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
import { newIdentityPasswordResetPath, signInPath, signUpPath } from "@/routes"

export default function Login() {
  return (
    <AuthLayout
      title="Log in to your account"
      description="Enter your email and password below to log in"
    >
      <Head title="Log in" />
      <Form
        method="post"
        action={signInPath()}
        resetOnSuccess={["password"]}
        className="flex flex-col gap-6"
      >
        {({ processing, errors }) => (
          <>
            <FieldGroup>
              <Field>
                <FieldLabel htmlFor="email">Email address</FieldLabel>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  required
                  autoFocus
                  tabIndex={1}
                  autoComplete="email"
                  placeholder="email@example.com"
                />
                <FieldError
                  errors={errors.email?.map((message) => ({ message }))}
                />
              </Field>

              <Field>
                <div className="flex items-center">
                  <FieldLabel htmlFor="password">Password</FieldLabel>
                  <TextLink
                    href={newIdentityPasswordResetPath()}
                    className="ml-auto text-sm"
                    tabIndex={5}
                  >
                    Forgot password?
                  </TextLink>
                </div>
                <Input
                  id="password"
                  type="password"
                  name="password"
                  required
                  tabIndex={2}
                  autoComplete="current-password"
                  placeholder="Password"
                />
                <FieldError
                  errors={errors.password?.map((message) => ({ message }))}
                />
              </Field>

              <Button
                type="submit"
                className="mt-4 w-full"
                tabIndex={4}
                disabled={processing}
              >
                {processing && <Spinner />}
                Log in
              </Button>
            </FieldGroup>

            <div className="text-muted-foreground text-center text-sm">
              Don&apos;t have an account?{" "}
              <TextLink href={signUpPath()} tabIndex={5}>
                Sign up
              </TextLink>
            </div>
          </>
        )}
      </Form>
    </AuthLayout>
  )
}
