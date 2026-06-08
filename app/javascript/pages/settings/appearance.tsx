import { Head } from "@inertiajs/react"

import AppearanceTabs from "@/components/appearance-tabs"
import HeadingSmall from "@/components/heading-small"
import AppLayout from "@/layouts/app-layout"
import SettingsLayout from "@/layouts/settings/layout"
import { settingsAppearance } from "@/routes"
import type { BreadcrumbItem } from "@/types"

const breadcrumbs: BreadcrumbItem[] = [
  {
    title: "Appearance settings",
    href: settingsAppearance().url,
  },
]

export default function Appearance() {
  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsLayout>
        <div className="space-y-6">
          <HeadingSmall
            title="Appearance settings"
            description="Update your account's appearance settings"
          />
          <AppearanceTabs />
        </div>
      </SettingsLayout>
    </AppLayout>
  )
}
