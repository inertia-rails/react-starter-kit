import { Form, Head } from "@inertiajs/react"

import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import AuthLayout from "@/layouts/auth-layout"
import { identityPasswordResets, sessions } from "@/routes"

export default function ForgotPassword() {
  return (
    <AuthLayout
      title="Forgot password"
      description="Enter your email to receive a password reset link"
    >
      <Head title="Forgot password" />

      <div className="space-y-6">
        <Form action={identityPasswordResets.create()}>
          {({ processing, errors }) => (
            <>
              <Field>
                <FieldLabel htmlFor="email">Email address</FieldLabel>
                <Input
                  id="email"
                  type="email"
                  name="email"
                  autoComplete="off"
                  autoFocus
                  placeholder="email@example.com"
                />
                <FieldError
                  errors={errors.email?.map((message) => ({ message }))}
                />
              </Field>

              <div className="my-6 flex items-center justify-start">
                <Button className="w-full" disabled={processing}>
                  {processing && <Spinner />}
                  Email password reset link
                </Button>
              </div>
            </>
          )}
        </Form>
        <div className="text-muted-foreground space-x-1 text-center text-sm">
          <span>Or, return to</span>
          <TextLink href={sessions.new()}>log in</TextLink>
        </div>
      </div>
    </AuthLayout>
  )
}
