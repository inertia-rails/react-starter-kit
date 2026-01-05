import type { FlashData, SharedData } from "./index"

declare module "@inertiajs/core" {
  export interface InertiaConfig {
    sharedPageProps: SharedData
    flashDataType: FlashData
    errorValueType: string[]
  }
}
