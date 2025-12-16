import { Form, Head } from "@inertiajs/react"

import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldError,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import AuthLayout from "@/layouts/auth-layout"
import { signInPath, signUpPath } from "@/routes"

export default function Register() {
  return (
    <AuthLayout
      title="Create an account"
      description="Enter your details below to create your account"
    >
      <Head title="Register" />
      <Form
        method="post"
        action={signUpPath()}
        resetOnSuccess={["password", "password_confirmation"]}
        disableWhileProcessing
        className="flex flex-col gap-6"
      >
        {({ processing, errors }) => (
          <>
            <FieldGroup>
              <Field>
                <FieldLabel htmlFor="name">Name</FieldLabel>
                <Input
                  id="name"
                  type="text"
                  name="name"
                  required
                  autoFocus
                  tabIndex={1}
                  autoComplete="name"
                  disabled={processing}
                  placeholder="Full name"
                />
                <FieldError
                  errors={errors.name?.map((message) => ({ message }))}
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="email">Email address</FieldLabel>
                <Input
                  id="email"
                  type="email"
                  name="email"
                  required
                  tabIndex={2}
                  autoComplete="email"
                  placeholder="email@example.com"
                />
                <FieldError
                  errors={errors.email?.map((message) => ({ message }))}
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="password">Password</FieldLabel>
                <Input
                  id="password"
                  type="password"
                  name="password"
                  required
                  tabIndex={3}
                  autoComplete="new-password"
                  placeholder="Password"
                />
                <FieldError
                  errors={errors.password?.map((message) => ({ message }))}
                />
              </Field>

              <Field>
                <FieldLabel htmlFor="password_confirmation">
                  Confirm password
                </FieldLabel>
                <Input
                  id="password_confirmation"
                  type="password"
                  name="password_confirmation"
                  required
                  tabIndex={4}
                  autoComplete="new-password"
                  placeholder="Confirm password"
                />
                <FieldError
                  errors={errors.password_confirmation?.map((message) => ({
                    message,
                  }))}
                />
              </Field>

              <Button type="submit" className="mt-2 w-full" tabIndex={5}>
                {processing && <Spinner />}
                Create account
              </Button>
            </FieldGroup>

            <div className="text-muted-foreground text-center text-sm">
              Already have an account?{" "}
              <TextLink href={signInPath()} tabIndex={6}>
                Log in
              </TextLink>
            </div>
          </>
        )}
      </Form>
    </AuthLayout>
  )
}
