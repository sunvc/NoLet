export type TaskEvent = string;
export const TaskEvent = {
  STATE_CHANGED: 'state_changed'
};

export type INTERNAL_TASK_STATE = string;
export const INTERNAL_TASK_STATE = {
  CANCELING: 'canceling',
  CANCELED: 'canceled',
  PAUSED: 'paused',
  SUCCESS: 'success',
  RUNNING: 'running',
  PAUSING: 'pausing',
  ERROR: 'error'
};

export type TaskState = string;

export const TaskState = {
  CANCELED: 'canceled',
  ERROR: 'error',
  RUNNING: 'running',
  PAUSED: 'paused',
  SUCCESS: 'success'
};

export function taskStateFromInternalTaskState(state: INTERNAL_TASK_STATE): TaskState {
  switch (state) {
    case INTERNAL_TASK_STATE.RUNNING:
    case INTERNAL_TASK_STATE.PAUSING:
    case INTERNAL_TASK_STATE.CANCELING:
      return TaskState.RUNNING;
    case INTERNAL_TASK_STATE.PAUSED:
      return TaskState.PAUSED;
    case INTERNAL_TASK_STATE.SUCCESS:
      return TaskState.SUCCESS;
    case INTERNAL_TASK_STATE.CANCELED:
      return TaskState.CANCELED;
    case INTERNAL_TASK_STATE.ERROR:
      return TaskState.ERROR;
    default:
      return TaskState.ERROR;
  }
}
