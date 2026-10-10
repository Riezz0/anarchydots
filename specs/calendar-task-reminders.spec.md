# Feature: Calendar Tasks and Reminders

## Overview

Allow users to select a day in the Anarchy-Bar calendar, create a task with a due time, and receive a persistent popup reminder before it is due. Tasks and their completion/reminder state are stored locally so they survive Quickshell restarts.

## Functional Requirements

### FR-001: Select a date
When the user clicks a valid day in the calendar, the system shall select that date and show its tasks and task-creation controls.

### FR-002: Create a task
While a date is selected, when the user submits a non-empty task title, valid due time, and reminder preset, the system shall save the task for that date.

### FR-003: Reminder presets
When the user creates a task, the system shall allow reminders at the due time or 5, 10, 15, 30, or 60 minutes beforehand.

### FR-004: Persistent local storage
The system shall save tasks, due times, completion state, and reminder state to a local user data file and reload them at startup.

### FR-005: Fire reminders
While Quickshell is running, when a pending task's selected reminder time arrives, the system shall display a persistent Anarchy-Bar popup until the user dismisses it.

### FR-006: Recover missed reminders
When Quickshell starts, the system shall show once any uncompleted, unacknowledged task whose reminder time passed while Quickshell was stopped, provided the task is not already overdue.

### FR-007: Skip expired reminders
When a task is already overdue at startup or when its reminder is checked, the system shall not display a late reminder.

### FR-008: Manage tasks
When viewing a selected date, the user shall be able to mark its tasks complete or delete them.

### FR-009: Acknowledge reminders
When the user dismisses a task reminder or completes/deletes its task, the system shall persist that acknowledgement and remove the active popup.

## Non-Functional Requirements

### Performance
- Reminder scheduling shall use a lightweight periodic check with at most 30 seconds of normal scheduling delay.
- Calendar rendering shall remain responsive with a practical personal task list.

### Security and Privacy
- Tasks shall remain in a local file under the user's data directory; no network service shall receive task content.
- Task titles shall be displayed as text and never interpreted as rich markup or commands.

### Reliability
- Invalid task-file data shall not be silently overwritten.
- A task shall be persisted before its reminder is considered delivered.

## Acceptance Criteria

### AC-001: Create a task from a calendar date
Given the calendar is open, when the user clicks a day, enters a title and valid due time, chooses a reminder preset, and saves, then the task appears in that day's task list and is stored locally.

### AC-002: Reminder arrives while the shell is running
Given a saved incomplete task, when its selected reminder time is reached, then a persistent popup displays the task title and due time until dismissed.

### AC-003: Recover a missed reminder
Given Quickshell was stopped during a task's reminder time but the due time is still in the future, when Quickshell starts, then the task reminder appears once.

### AC-004: Skip an overdue task reminder
Given a task's due time has passed while Quickshell was stopped, when Quickshell starts, then no reminder popup is shown for that task.

### AC-005: Complete or delete a task
Given a selected date has a saved task, when the user marks it complete or deletes it, then the updated task state persists and completed/deleted tasks are not reminded.

### AC-006: Reject invalid task input
Given the task form has an empty title, malformed time, or a due time in the past, when the user attempts to save, then the task is not created and a clear validation message is shown.

## Error Handling

| Error condition | Expected behavior |
|---|---|
| Task file does not exist | Create an empty task store in the user data directory. |
| Task file contains invalid JSON | Keep the file untouched, disable task writes, and show a readable error. |
| Task file cannot be written | Keep the UI responsive and show a storage error; do not claim the task was saved. |
| Invalid title, time, or past due time | Keep the form open and show validation feedback. |

## Implementation TODO

### Data and scheduling
- [x] Add local task persistence and startup loading.
- [x] Add reminder scheduler and missed-reminder recovery.
- [x] Add persistent reminder popup with dismissal.

### Calendar UI
- [x] Select dates and mark dates containing tasks.
- [x] Add task form with title, due time, and reminder presets.
- [x] Add completion and deletion controls.
- [x] Validate inputs and show storage errors.

### Testing
- [x] Run QML syntax validation and JSON validation.
- [ ] Manually verify task-store parsing, due-time validation, reminder delivery, missed reminders, and popup behavior in a running Quickshell session.

## Out of Scope

- Recurring tasks, task synchronization, and network-backed storage.
- Native desktop notifications, snooze actions, and reminders after a task is already overdue.
