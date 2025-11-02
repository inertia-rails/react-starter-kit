import { Link, usePage } from "@inertiajs/react"
import type { PropsWithChildren } from "react"

import Heading from "@/components/heading"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { cn } from "@/lib/utils"
import {
  settingsAppearancePath,
  settingsEmailPath,
  settingsPasswordPath,
  settingsProfilePath,
  settingsSessionsPath,
} from "@/routes"
import type { NavItem } from "@/types"

const sidebarNavItems: NavItem[] = [
  {
    title: "Profile",
    href: settingsProfilePath(),
    icon: null,
  },
  {
    title: "Email",
    href: settingsEmailPath(),
    icon: null,
  },
  {
    title: "Password",
    href: settingsPasswordPath(),
    icon: null,
  },
  {
    title: "Sessions",
    href: settingsSessionsPath(),
    icon: null,
  },
  {
    title: "Appearance",
    href: settingsAppearancePath(),
    icon: null,
  },
]

export default function SettingsLayout({ children }: PropsWithChildren) {
  const { url } = usePage()

  return (
    <div className="px-4 py-6">
      <Heading
        title="Settings"
        description="Manage your profile and account settings"
      />

      <div className="flex flex-col space-y-8 lg:flex-row lg:space-y-0 lg:space-x-12">
        <aside className="w-full max-w-xl lg:w-48">
          <nav className="flex flex-col space-y-1 space-x-0">
            {sidebarNavItems.map((item, index) => (
              <Button
                key={`${item.href}-${index}`}
                size="sm"
                variant="ghost"
                asChild
                className={cn("w-full justify-start", {
                  "bg-muted": url === item.href,
                })}
              >
                <Link href={item.href}>
                  {item.icon && <item.icon className="h-4 w-4" />}
                  {item.title}
                </Link>
              </Button>
            ))}
          </nav>
        </aside>

        <Separator className="my-6 md:hidden" />

        <div className="flex-1 md:max-w-2xl">
          <section className="max-w-xl space-y-12">{children}</section>
        </div>
      </div>
    </div>
  )
}
