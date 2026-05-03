# 000 - Project Context

## Project Name

SpecBridge

## Purpose

SpecBridge is a standard connector for turning ChatGPT/Codex context into autonomous Claude Code execution.

## Core Thesis

Users increasingly define product goals, architecture decisions, and implementation intent inside ChatGPT/Codex.

The problem is that this context does not naturally become controlled implementation work inside Claude Code.

SpecBridge solves this by converting ChatGPT/Codex context into structured repository context, execution contracts, autonomy policies, GitHub workflow actions, validation gates, Codex review, and final result reports.

## Product Mode

The primary mode is Vibe Autopilot.

Vibe Autopilot means ordinary development work should execute without asking the user for step-by-step permission.

The system stops only for policy boundaries, real risk, contradictory specifications, impossible acceptance criteria, or missing critical information.

## Main Actors

- User: defines goals and receives final results.
- ChatGPT/Codex: captures intent, structures context, defines specs, reviews implementation.
- SpecBridge: creates contracts, enforces policy, coordinates execution and reporting.
- Claude Code: implements autonomously inside the approved scope.
- GitHub: stores repository state, issues, branches, pull requests, CI, and audit trail.

## Current Stage

This repository is in foundation phase.

No product implementation code should be added until the base contract, policy, autonomy profiles, risk rules, and MVP specs exist.
