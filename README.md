Poniard
=======

A lightweight gem that provides an alternative to Rails controllers. It uses
parameter based dependency injection to explicitly make dependencies available,
rather than mixing them all in from a base class. This allows controllers to be
properly tested in isolation, bringing all the design benefits of TDD (as
opposed to "test-first" development, which is more common with the standard
integration style controller tests).

Poniard is designed to be compatible with standard controllers. It can be used
for your entire application, just one action, or anything in between.

Example
-------

A poniard controller is slightly more verbose than the what you may be used to.
In particular, all the dependencies of a method (`response` in the following
example) must be declared as parameters to your method. Poniard will introspect
the method before calling, and ensure that the correct values are passed. These
values will for the most part be the same objects you normally deal with in
Rails (`session`, `flash`, etc...).

The following controller renders the default index template, setting the
instance variables `@message`.

```ruby
module Controller
  class Registration
    def index(response)
      response.default message: "hello"
    end
  end
end
```

This is differs from traditional controllers in two ways: passing variables to
the template is done with an explicit method call rather than instance variable
assignment, and dependencies that would normally be made available by
a superclass are passed in as parameters to the method.

Wiring this controller into an application is a one-liner in the normal
controller definition.

```ruby
class RegistrationsController < ApplicationController
  include Poniard::Controller

  provided_by Controller::Registration
end
```

Traditional and poniard styles can be used together. Some actions can be
implemented in the normal controller, others can be provided by an injectable
one.

```ruby
class RegistrationsController < ApplicationController
  include Poniard::Controller

  # index action provided by this class
  provided_by Controller::Registration

  # All controller features work in harmony with poniard, such as this
  before_filter :require_user

  # update action implemented normally
  def update
    # ...
  end
end
```

### Sources

Poniard knows about all the standard controller objects such as `response`,
`session` and `flash`. Domain specific definitions are then layered on top by
creating **sources**:

```ruby
class Source
  class Registration
    def finder
      Registration.accepted
    end

    def current_registration
      Registration.find(params[:id])
    end
  end
end
```

This is wired up in the `provided_by` call:

```ruby
provided_by Controller::Registration, sources: [
  Source::Registration
]
```

Any number of sources can be used, making it easy to reuse logic across
controllers.

Testing
-------

Set up a common injector for the scope of your controller that knows about
common sources that all tests require (such as `response`). Add extra required
sources on a per test basis (`finder` in the below example).

```ruby
require 'poniard/injector'
require 'controller/registration'

describe Controller::Registration do
  let(:response) { double("Poniard::ControllerSource") }
  let(:injector) { Poniard::Injector.new([
    response: response.as_null_object
  ]) }

  def dispatch(action, overrides = {})
    injector.dispatch described_class.new.method(action), overrides
  end

  describe '#index' do
    it 'should render default action with all registrations' do
      finder = double(all: ['r1'])
      response.should_receive(:default).with(registrations: ['r1'])

      dispatch :index, finder: finder
    end
  end
end
```

Techniques
----------

### Built-in sources

See the [YARD docs][yard] for all the built in controller sources.

[yard]: http://rubydoc.info/github/xaviershay/poniard/master/Poniard/ControllerSource/

### Layouts

If a `layout` method is implemented in a controller, it will be used to select
a layout for the controller. This is equivalent to adding a custom `layout`
method to a standard controller.

### Mime types

The Rails `respond_to` API is not very Object-Oriented, so is hard to test in
isolation. Poniard provides an alternative [`respond_with`][respond-with] that
allows you to provide a response object, which is much easier to work with.

[respond-with]: http://rubydoc.info/github/xaviershay/poniard/master/Poniard/ControllerSource/Response.html#respond_with-instance_method

### Authorization

Poniard sources can raise exceptions to indicate authorization failure, which
can then be handled in a standard manner using `rescue_from`.

```ruby
module Source
  class Admin
    def current_admin(session)
      User.find_by_id(session[:admin_id])
    end

    def authorized_admin(current_admin)
      current_admin || raise(ResponseException::Unauthorized)
    end
  end
end
```

This can be slightly weird if the method being authorized does not actually
need to interact with the admin, since it will have a method parameter that
is never used.

```ruby
RSpec::Matchers.define :have_param do |attribute|
  match do |obj|
    obj.parameters.map(&:last).include?(attribute)
  end
end

def instance_method(name)
  described_class.new.method(name)
end

it 'requires authorization' do
  instance_method(:index).should have_param(:authorized_admin)
end
```

Developing
----------

### Status

Not widely used. May be some obvious things missing from built-in controller
sources that you will have to add.

### Compatibility

Requires 1.9 or above.

### Support

Make a [new github issue](https://github.com/xaviershay/poniard/issues/new).

### Contributing

Fork and patch! Please update the README and other documentation if you add
features.
