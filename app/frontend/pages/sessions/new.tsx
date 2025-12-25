import { Form, Head } from "@inertiajs/react"

import InputError from "@/components/input-error"
import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
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
            <div className="grid gap-6">
              <div className="grid gap-2">
                <Label htmlFor="email">Email address</Label>
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
                <InputError messages={errors.email} />
              </div>

              <div className="grid gap-2">
                <div className="flex items-center">
                  <Label htmlFor="password">Password</Label>
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
                <InputError messages={errors.password} />
              </div>

              <Button
                type="submit"
                className="mt-4 w-full"
                tabIndex={4}
                disabled={processing}
              >
                {processing && <Spinner />}
                Log in
              </Button>
            </div>

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
