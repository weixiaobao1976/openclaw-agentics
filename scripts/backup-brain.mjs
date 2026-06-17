#!/usr/bin/env node
/**
 * backup-brain.mjs — 脑镜像备份脚本
 * 
 * 备份本地核心脑文件到 Git 的 brain-backup 分支
 * 
 * 用法:
 *   node backup-brain.mjs [--force]          # 备份并推送
 *   node backup-brain.mjs --force            # 强制推送（覆盖远程分支）
 *   node backup-brain.mjs --status           # 仅检查当前状态
 */

import { execSync, spawnSync } from 'child_process';
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const WORKSPACE = process.env.WORKSPACE || dirname(__dirname);

const BRAIN_FILES = [
  'AGENTS.md',
  'MEMORY.md',
  'TOOLS.md',
  'SOUL.md',
  'USER.md',
  'IDENTITY.md',
  'HEARTBEAT.md',
];

const BRAIN_DIRS = [
  'memory/',
  'knowledge/',
  'skills/',
];

// 脚本路径：部分在 workspace 内，部分在 ~/.openclaw/scripts/
const OPENCLAW_SCRIPTS = '/home/zbc2/.openclaw/scripts';
const SCRIPTS_TO_BACKUP = [
  'scripts/backup-brain.mjs',
  'scripts/mirror-sync.sh',
  // 外部脚本（~/.openclaw/scripts/）
  'self-learn.mjs',
  'self-heal-check.mjs',
  'weather-forecast.js',
];

const BRANCH = 'brain-backup';
const REMOTE = 'origin';

function log(msg, type = 'info') {
  const prefix = type === 'error' ? '❌' : type === 'warn' ? '⚠️' : '✅';
  console.log(`${prefix} ${msg}`);
}

function run(cmd, opts = {}) {
  const result = spawnSync(cmd, opts.shell ? [] : opts.args || [], {
    cwd: WORKSPACE,
    shell: opts.shell,
    encoding: 'utf-8',
    timeout: opts.timeout || 30000,
    env: { ...process.env, GIT_ASKPASS: 'echo' },
  });
  if (result.status !== 0 && !opts.allowFail) {
    log(`命令失败: ${cmd} (exit ${result.status})`, 'error');
    if (result.stderr) console.error(result.stderr);
    if (result.stdout) console.log(result.stdout);
    process.exit(1);
  }
  return result.stdout || '';
}

function checkGit() {
  const remote = run('git', { args: ['remote', 'get-url', REMOTE], allowFail: true });
  if (!remote || remote.trim().length === 0) {
    log('未找到 Git 远程仓库', 'warn');
    return false;
  }
  log(`远程仓库: ${remote.trim()}`);
  return true;
}

function checkAuth() {
  // 尝试 gh auth status
  const gh = spawnSync('gh', ['auth', 'status'], {
    cwd: WORKSPACE,
    encoding: 'utf-8',
    timeout: 10000,
  });
  if (gh.status === 0) {
    log('GitHub CLI 认证正常');
    return true;
  }

  // 尝试 SSH
  const ssh = spawnSync('ssh', ['-T', 'git@github.com'], {
    encoding: 'utf-8',
    timeout: 10000,
  });
  if (ssh.stderr && ssh.stderr.includes('authenticated')) {
    log('SSH 认证正常');
    return true;
  }

  log('GitHub 认证失效 — gh auth 和 SSH 都不可用', 'error');
  log('请运行: gh auth login -h github.com', 'warn');
  return false;
}

function ensureBranch() {
  const branches = run('git', { args: ['branch', '--list', BRANCH] }).trim();
  if (!branches.includes(BRANCH)) {
    log(`创建新分支: ${BRANCH}`);
    run('git', { args: ['checkout', '-b', BRANCH] });
  } else {
    run('git', { args: ['checkout', BRANCH] });
  }
}

function backup() {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const manifest = { timestamp, files: [], dirs: [] };

  // 备份脑文件
  for (const f of BRAIN_FILES) {
    const path = join(WORKSPACE, f);
    if (existsSync(path)) {
      manifest.files.push(f);
    }
  }

  // 备份目录
  for (const d of BRAIN_DIRS) {
    const path = join(WORKSPACE, d);
    if (existsSync(path)) {
      manifest.dirs.push(d);
    }
  }

  // 备份脚本（workspace 内 + ~/.openclaw/scripts/）
  for (const s of SCRIPTS_TO_BACKUP) {
    let path = join(WORKSPACE, s);
    if (!existsSync(path)) {
      // 尝试外部脚本目录
      path = join(OPENCLAW_SCRIPTS, s);
    }
    if (existsSync(path)) {
      manifest.files.push(s);
    }
  }

  // 创建 manifest 文件
  const manifestPath = join(WORKSPACE, '_brain-backup-manifest.json');
  writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));

  // Git add
  run('git', { args: ['add', '-A'] });

  const status = run('git', { args: ['status', '--short'] });
  if (status.trim().length === 0) {
    log('没有需要备份的变更');
    return false;
  }

  log(`待备份文件: ${manifest.files.length} 个文件, ${manifest.dirs.length} 个目录`);

  // Commit
  run('git', { args: ['commit', '-m', `brain backup: ${timestamp}`] });

  return true;
}

function push(force = false) {
  try {
    const flag = force ? '--force' : '';
    run('git', { args: ['push', REMOTE, BRANCH, flag] });
    log(`已推送到 ${REMOTE}/${BRANCH}${force ? ' (强制)' : ''}`);
  } catch (e) {
    log(`推送失败: ${e.message}`, 'error');
    log('可能是网络问题或认证失效，请检查 GitHub 连接', 'warn');
    return false;
  }
  return true;
}

function status() {
  const hasRemote = checkGit();
  const hasAuth = checkAuth();

  // 当前分支
  const currentBranch = run('git', { args: ['branch', '--show-current'] }).trim();
  log(`当前分支: ${currentBranch}`);

  // 本地脑文件状态
  const modified = [];
  const missing = [];
  for (const f of [...BRAIN_FILES, ...SCRIPTS_TO_BACKUP]) {
    const path = join(WORKSPACE, f);
    if (!existsSync(path)) {
      missing.push(f);
    } else {
      const stat = run('git', { args: ['status', '--porcelain', f], allowFail: true });
      if (stat.trim().length > 0) modified.push(f);
    }
  }

  if (modified.length > 0) {
    log(`有 ${modified.length} 个文件有未提交变更`, 'warn');
  }
  if (missing.length > 0) {
    log(`缺失 ${missing.length} 个文件: ${missing.join(', ')}`, 'error');
  }

  // brain-backup 分支
  const backupBranch = run('git', { args: ['branch', '--list', BRANCH], allowFail: true }).trim();
  if (backupBranch.includes(BRANCH)) {
    const lastCommit = run('git', { args: ['log', `${REMOTE}/${BRANCH}`, '-1', '--format=%h %s'], allowFail: true }).trim();
    log(`brain-backup 分支: 上次提交 ${lastCommit}`);
  } else {
    log('brain-backup 分支不存在', 'warn');
  }

  return { hasRemote, hasAuth, currentBranch, modified, missing };
}

// Main
const args = process.argv.slice(2);
const force = args.includes('--force');

if (args.includes('--status')) {
  status();
  process.exit(0);
}

log('🧠 开始脑镜像备份...', 'info');

const hasRemote = checkGit();
if (!hasRemote) {
  log('无 Git 远程仓库，跳过备份', 'warn');
  process.exit(1);
}

const hasAuth = checkAuth();
if (!hasAuth) {
  log('GitHub 认证失效，无法推送。请先运行: gh auth login -h github.com', 'error');
  process.exit(1);
}

ensureBranch();
const hadChanges = backup();

if (hadChanges) {
  push(force);
} else {
  // 即使没变更也尝试 push 确认分支存在
  push(force);
}

log('脑镜像备份完成 ✅');
