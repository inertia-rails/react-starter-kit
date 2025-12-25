import type { SharedData } from "./index"

declare module "@inertiajs/core" {
  export interface InertiaConfig {
    sharedPageProps: SharedData
    errorValueType: string[]
  }
}
