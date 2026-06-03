// Minimal reactive store. Sections re-render on change; no virtual DOM needed
// for a single-operator admin panel with paginated lists.

export function createStore(initial) {
  let state = initial;
  const subscribers = new Set();

  return {
    get() {
      return state;
    },
    /** Merge a patch (object) or apply an updater (fn) and notify subscribers. */
    set(patch) {
      state = typeof patch === "function" ? patch(state) : { ...state, ...patch };
      subscribers.forEach((fn) => fn(state));
      return state;
    },
    subscribe(fn) {
      subscribers.add(fn);
      return () => subscribers.delete(fn);
    },
  };
}
