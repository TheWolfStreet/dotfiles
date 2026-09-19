## Goal

Write code that is correct, simple, readable, local, fast, and unsurprising.

Priority:

1. Correctness
2. Simplicity
3. Readability
4. Locality
5. Performance
6. Maintainability
7. Extensibility only when required

Prefer fewer concepts, files, types, indirections, allocations, branches, dependencies, and lines.

Do not optimize for hypothetical requirements.

## Before changing code

Read the relevant code, trace the real execution path, identify the actual problem, and make the smallest direct change that solves it.

Do not redesign unrelated code.

Do not invent abstractions before understanding the problem.

## Simplicity

Prefer ordinary code:

* explicit `if` statements,
* early returns,
* straightforward loops,
* concrete types,
* structs for passive data,
* enums for real finite states,
* local functions and state.

Avoid clever expressions, chained ternaries, unnecessary lambdas, forwarding layers, generic machinery, and excessive file splitting.

Keep the call graph shallow and behavior close to where it is used.

## Abstractions

An abstraction must solve a current problem.

Add one only when it meaningfully removes duplication, protects invariants, represents real variation, improves correctness, or substantially simplifies an interface.

Do not add managers, services, providers, factories, repositories, adapters, interfaces, strategies, dependency injection, or similar layers without a concrete need.

Do not create interfaces with one implementation unless runtime polymorphism is actually needed.

Prefer deletion and consolidation over reorganizing code into more layers.

## C++

Use C++20 unless the project requires otherwise.

Follow existing project style.

Prefer:

* `snake_case`,
* scoped enums,
* structs for plain data, built with designated initializers,
* classes only when state/invariants justify them,
* automatic storage,
* `std::unique_ptr` for exclusive ownership,
* `std::shared_ptr` only for genuinely shared ownership,
* `const` and `[[nodiscard]]` where appropriate,
* explicit ownership and error handling.

Avoid unnecessary allocation, copying, virtual dispatch, `std::function`, templates, metaprogramming, and heap-owned objects.

Templates are fine at the API edge when they remove user boilerplate (e.g. types inferred from lambda arguments); keep them out of internals.

Use language features because they simplify the code, not because they exist.

## Control flow

Keep nesting shallow.

Prefer:

```cpp
if (!request.valid()) {
    return error::invalid_request;
}

if (!route) {
    return error::route_not_found;
}

return execute_route(*route, request);
```

Use ternaries only for obvious trivial value selection.

Prefer a readable loop over a complicated algorithm expression.

Do not extract small helpers when doing so makes the execution path harder to follow.

## Errors

Keep failure behavior explicit.

Follow the project's existing error model.

Prefer simple result/error enums for expected failures.

Do not silently swallow failures.

Use assertions for programmer errors, not expected runtime failures.

## Performance

Prefer naturally efficient designs.

Watch allocations, copies, syscalls, locking, repeated work, data layout, and hot-path indirection.

Do not introduce complex optimizations without evidence they matter.

Do not sacrifice simplicity for speculative performance.

## APIs and architecture

Make the common case short and obvious.

Prefer good defaults over configuration. Options are aggregates with safe defaults applied automatically; zero config must work.

Defaults are safe: bounded sizes, timeouts, and restrictive policies.

Optional features that pull dependencies are compile-time flags, off when heavy.

Do not add builders for simple structs.

Do not require several objects to perform one simple operation.

Keep architecture proportional to the problem.

Prefer:

`request -> router -> handler -> response`

over layers that mainly forward calls.

Keep related code together. Do not create a file for every type.

## Comments

Comment only what the code cannot reasonably express:

* protocol/API quirks and doc references,
* platform quirks,
* subtle lifetime rules,
* compatibility workarounds,
* important invariants,
* non-obvious measured optimizations.

Explain why, never what. No narration, restated names, changelogs, or commented-out code.

## Dependencies and concurrency

Avoid new dependencies when a small clear implementation is sufficient.

Keep concurrency explicit.

Do not introduce thread pools, queues, executors, locking abstractions, or hidden threads without a real requirement.

Use the project's existing event loop or concurrency model.

## Networking

Keep the connection path traceable:

`accept -> read -> parse -> route -> handle -> serialize -> write -> close/reuse`

Handle partial I/O, limits, timeouts, and errors explicitly.

Do not hide socket behavior behind unnecessary generic abstractions.

## Scope

Keep diffs focused.

Do not rename, reformat, refactor, or redesign unrelated code.

Remove obsolete code when replacing something.

Do not leave old and new approaches in parallel without a real reason.

Commits: no co-author trailers, session ids, or tool attribution.

## Testing and review

During normal implementation, do not repeatedly re-read, re-check, or run broad test suites.

Do enough checking to avoid obvious mistakes, then stop.

Run only focused tests directly relevant to the changed path when needed.

Do not run exhaustive tests, broad reviews, repeated verification passes, or speculative checks unless explicitly asked.

When I ask for **review**, then inspect the diff carefully, look for correctness issues, unnecessary complexity, dead code, performance problems, and run the appropriate affected tests.

## Decision rule

If two solutions work, prefer the one with:

* fewer moving parts,
* fewer concepts,
* fewer files and types,
* clearer ownership,
* shorter execution paths,
* more obvious failure behavior,
* less data movement,
* less hidden behavior.

If the simple solution satisfies the actual requirement, use it.

Write software for the person debugging it at 3 a.m.

Make behavior obvious. Keep state local. Keep the call graph shallow. Add less. Delete more.
