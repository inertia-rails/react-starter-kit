import { Transition } from "@headlessui/react"
import { Form, Head, usePage } from "@inertiajs/react"

import DeleteUser from "@/components/delete-user"
import HeadingSmall from "@/components/heading-small"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import AppLayout from "@/layouts/app-layout"
import SettingsLayout from "@/layouts/settings/layout"
import { settingsProfiles } from "@/routes"
import type { BreadcrumbItem } from "@/types"

const breadcrumbs: BreadcrumbItem[] = [
  {
    title: "Profile settings",
    href: settingsProfiles.show().url,
  },
]

export default function Profile() {
  const { auth } = usePage().props

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={breadcrumbs[breadcrumbs.length - 1].title} />

      <SettingsLayout>
        <div className="space-y-6">
          <HeadingSmall
            title="Profile information"
            description="Update your name"
          />

          <Form
            action={settingsProfiles.update()}
            options={{
              preserveScroll: true,
            }}
            className="space-y-6"
          >
            {({ errors, processing, recentlySuccessful }) => (
              <>
                <Field>
                  <FieldLabel htmlFor="name">Name</FieldLabel>

                  <Input
                    id="name"
                    name="name"
                    defaultValue={auth.user.name}
                    required
                    autoComplete="name"
                    placeholder="Full name"
                  />

                  <FieldError
                    errors={errors.name?.map((message) => ({ message }))}
                  />
                </Field>

                <div className="flex items-center gap-4">
                  <Button disabled={processing}>Save</Button>

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

        <DeleteUser />
      </SettingsLayout>
    </AppLayout>
  )
}
