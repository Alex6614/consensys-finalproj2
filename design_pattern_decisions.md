# Design Pattern Decisions

*   Circuit Breaker
    *   I implemented this with a boolean that checks if the contract is "stopped." Only the admin should have this.
    *   This allows the contract to stop if a bug has been detected and provides time for developers to fix the bug.
*   Fail early and fail loud
    *   I implemented this in multiple functions through the use of modifiers. For example, I  check if the user is the source of a resource with "isSource", and as another example I check if the emergency stop is active before the contract executes functions like "notify()".
    *   I did this because debugging is easier and the end user will be notified of failure quickly.
*   Restricting Access
    *   Some functions, like the one that activates the circuit breaker, requires the admin account
    *   I did this because some functions should not be accessible by everyone.