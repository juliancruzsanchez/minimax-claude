#!/usr/bin/env node
// Normalizes `clauditor hook post-tool-use` output into a single valid JSON object.
//
// Upstream clauditor's post-tool-use module initializer calls init_pre_tool_use(),
// which fires handlePreToolUseHook() as a side effect. Both handlers then write to
// stdout, so the subcommand emits "{}{}" -- two concatenated objects. Hook runtimes
// parse replies with JSON.parse semantics and reject the second object as trailing
// characters, discarding the whole reply. Present in 1.28.0 and 1.30.0.
//
// This shim keeps the post-tool-use handler's object (written last) and drops the
// stray pre-tool-use one. stderr and the exit code pass through untouched.

import { spawn } from 'node:child_process';

const CLAUDITOR = process.env.CLAUDITOR_BIN || 'clauditor';
const SUBARGS = ['hook', 'post-tool-use'];

function readStdin() {
  return new Promise((resolve, reject) => {
    let data = '';
    process.stdin.setEncoding('utf-8');
    process.stdin.on('data', (chunk) => (data += chunk));
    process.stdin.on('end', () => resolve(data));
    process.stdin.on('error', reject);
  });
}

// Collect every complete top-level {...} span, string- and escape-aware, so braces
// inside string values do not throw off the depth count.
function scanObjects(text) {
  const found = [];
  for (let i = 0; i < text.length; i++) {
    if (text[i] !== '{') continue;
    let depth = 0;
    let inString = false;
    let escaped = false;
    let end = -1;
    for (let j = i; j < text.length; j++) {
      const c = text[j];
      if (inString) {
        if (escaped) escaped = false;
        else if (c === '\\') escaped = true;
        else if (c === '"') inString = false;
        continue;
      }
      if (c === '"') inString = true;
      else if (c === '{') depth++;
      else if (c === '}' && --depth === 0) {
        end = j;
        break;
      }
    }
    if (end === -1) break; // unterminated object; nothing usable after it
    found.push(text.slice(i, end + 1));
    i = end;
  }
  return found;
}

// Last object wins: the post-tool-use handler always writes after the stray
// pre-tool-use one. Walk backwards until one parses.
function pickReply(stdout) {
  const candidates = scanObjects(stdout).reverse();
  for (const candidate of candidates) {
    try {
      const parsed = JSON.parse(candidate);
      if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) return parsed;
    } catch {
      // ignore and try the previous object
    }
  }
  return {};
}

const stdin = await readStdin();

let child;
try {
  child = spawn(CLAUDITOR, SUBARGS, { stdio: ['pipe', 'pipe', 'pipe'] });
} catch (err) {
  process.stderr.write(`clauditor-post-tool-use: failed to launch ${CLAUDITOR}: ${err.message}\n`);
  process.stdout.write('{}');
  process.exit(0);
}

let stdout = '';
let stderr = '';
child.stdout.setEncoding('utf-8');
child.stderr.setEncoding('utf-8');
child.stdout.on('data', (chunk) => (stdout += chunk));
child.stderr.on('data', (chunk) => (stderr += chunk));

child.on('error', (err) => {
  process.stderr.write(`clauditor-post-tool-use: ${err.message}\n`);
  process.stdout.write('{}');
  process.exit(0);
});

child.on('close', (code) => {
  if (stderr) process.stderr.write(stderr);
  process.stdout.write(JSON.stringify(pickReply(stdout)));
  // Preserve exit code: 2 carries a PostToolUse block reason on stderr.
  process.exit(code ?? 0);
});

child.stdin.end(stdin);