import { Transition } from "@headlessui/react"
import { Form, Head } from "@inertiajs/react"
import { useRef } from "react"

import HeadingSmall from "@/components/heading-small"
import InputError from "@/components/input-error"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import AppLayout from "@/layouts/app-layout"
import SettingsLayout from "@/layouts/settings/layout"
import { settingsPasswordPath } from "@/routes"
import type { BreadcrumbItem } from "@/types"

const breadcrumbs: BreadcrumbItem[] = [
  {
    title: "Password settings",
    href: settingsPasswordPath(),
  },
]

export default function Password() {
  const passwordInput = useRef<HTMLInputElement>(null)
  const currentPasswordInput = useRef<HTMLInputElement>(null)

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsLayout>
        <div className="space-y-6">
          <HeadingSmall
            title="Update password"
            description="Ensure your account is using a long, random password to stay secure"
          />

          <Form
            method="put"
            action={settingsPasswordPath()}
            options={{
              preserveScroll: true,
            }}
            resetOnError={["password", "password_challenge"]}
            resetOnSuccess
            className="space-y-6"
          >
            {({ errors, processing, recentlySuccessful }) => (
              <>
                <div className="grid gap-2">
                  <Label htmlFor="password_challenge">Current password</Label>

                  <Input
                    id="password_challenge"
                    name="password_challenge"
                    ref={currentPasswordInput}
                    type="password"
                    className="mt-1 block w-full"
                    autoComplete="current-password"
                    placeholder="Current password"
                  />

                  <InputError message={errors.password_challenge} />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="password">New password</Label>

                  <Input
                    id="password"
                    name="password"
                    ref={passwordInput}
                    type="password"
                    className="mt-1 block w-full"
                    autoComplete="new-password"
                    placeholder="New password"
                  />

                  <InputError message={errors.password} />
                </div>

                <div className="grid gap-2">
                  <Label htmlFor="password_confirmation">
                    Confirm password
                  </Label>

                  <Input
                    id="password_confirmation"
                    name="password_confirmation"
                    type="password"
                    className="mt-1 block w-full"
                    autoComplete="new-password"
                    placeholder="Confirm password"
                  />

                  <InputError message={errors.password_confirmation} />
                </div>

                <div className="flex items-center gap-4">
                  <Button disabled={processing}>Save password</Button>

                  <Transition
                    show={recentlySuccessful}
                    enter="transition ease-in-out"
                    enterFrom="opacity-0"
                    leave="transition ease-in-out"
                    leaveTo="opacity-0"
                  >
                    <p className="text-sm text-neutral-600">Saved</p>
                  </Transition>
                </div>
              </>
            )}
          </Form>
        </div>
      </SettingsLayout>
    </AppLayout>
  )
}
