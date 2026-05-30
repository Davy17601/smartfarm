# 05 — Calendar & Reminders tab

## Purpose
Schedule farm activities by date and keep reminders, with local notifications (1 day before + on the day) that fire even when the app is closed.

## Wireframe
```
┌──────────────────────────────────────┐
│ ប្រតិទិន                                │
│ ┌──────────────────────────────────┐ │
│ │   < ឧសភា 2026 >                    │ │  GraphicalDatePicker
│ │   M T W T F S S                    │ │  (selectedDate)
│ │   …  28 29 [30] 31 …               │ │
│ └──────────────────────────────────┘ │
│ សកម្មភាព · 30 ឧសភា                  + │  add activity (defaults to selDate)
│  ◯ ស្រោចទឹក            30 ឧសភា 08:00  │  tap → edit · ◯ toggle done · swipe del
│ ការរំឭកខាងមុខ                       + │  add reminder
│  ◯ បាច់ជី              02 មិថុនា 07:00 │
└──────────────────────────────────────┘
```

## State & ViewModel — `CalendarViewModel`
- `@Published activities, reminders, selectedDate`.
- `activities(on: date)` — same calendar day.
- `upcomingActivities(within:)`, `upcomingReminders(within:30)`.
- Activity CRUD + `toggleActivityCompleted`; Reminder CRUD + `toggleReminderCompleted`.
- On add/update: schedule notification (cancel if completed). On delete: cancel notification.
- Observes `NotificationService.$tappedItemID` → sets `selectedDate` to the tapped item's date.

## Notifications — `NotificationService`
- `requestAuthorization()` on first appearance.
- `schedule(id:title:body:date:)` creates two `UNCalendarNotificationTrigger`s: `-before` (date − 1 day) and `-day`. Past fire dates skipped.
- Foreground presentation enabled (banner+sound). Tap → publishes `tappedItemID`; `MainTabView` switches to the Calendar tab.

## Forms
- `AddEditActivityView` (`.add(Date)` / `.edit`): title, date+time, note, (+completed toggle when editing).
- `AddEditReminderView` (`.add` / `.edit`): title, dueDate, repeat picker, note, (+completed). `RepeatType.displayName` in Khmer.

## Interactions
- Tap row → edit sheet (`.sheet(item:)`). Tap ◯ → toggle done (strikethrough). Swipe → delete (cancels notification).

## Edge cases
- Permission denied → CRUD still works; no notifications (no crash).
- Day with no activities → "មិនមានសកម្មភាព"; no reminders → "មិនមានការរំឭក".
- `repeatType` stored but recurring scheduling is **v1-deferred** (single fire). Documented as known limitation.

## Acceptance criteria
- [ ] Create activity → notification scheduled (1-day-before + day-of) when in future.
- [ ] Tapping a delivered notification opens the Calendar tab on that date.
- [ ] Toggling complete cancels its pending notification.
- [ ] All CRUD persists across relaunch.
```
