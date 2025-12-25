import { Form, Head } from "@inertiajs/react"

import InputError from "@/components/input-error"
import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
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
            <div className="grid gap-6">
              <div className="grid gap-2">
                <Label htmlFor="name">Name</Label>
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
                <InputError messages={errors.name} className="mt-2" />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="email">Email address</Label>
                <Input
                  id="email"
                  type="email"
                  name="email"
                  required
                  tabIndex={2}
                  autoComplete="email"
                  placeholder="email@example.com"
                />
                <InputError messages={errors.email} />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="password">Password</Label>
                <Input
                  id="password"
                  type="password"
                  name="password"
                  required
                  tabIndex={3}
                  autoComplete="new-password"
                  placeholder="Password"
                />
                <InputError messages={errors.password} />
              </div>

              <div className="grid gap-2">
                <Label htmlFor="password_confirmation">Confirm password</Label>
                <Input
                  id="password_confirmation"
                  type="password"
                  name="password_confirmation"
                  required
                  tabIndex={4}
                  autoComplete="new-password"
                  placeholder="Confirm password"
                />
                <InputError messages={errors.password_confirmation} />
              </div>

              <Button type="submit" className="mt-2 w-full" tabIndex={5}>
                {processing && <Spinner />}
                Create account
              </Button>
            </div>

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
