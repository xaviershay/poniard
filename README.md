Poniard
=======

A lightweight gem that provides an alternative to Rails controllers. It uses
parameter based dependency injection to explicitly make dependencies available,
rather than mixing them all in from a base class. This allows you to properly
unit test your controllers in isolation, bringing all the design benefits of
TDD (as opposed to "test-first" development which is more common with the
standard integration style controller tests).

Poniard is designed to be compatible with standard controllers. You can use it
for your entire application, just one action, or anything in between.

Example
-------

A poniard controller is slightly more verbose than the what you may be used to.
In particular, you need to specify all the different dependencies you wish to
use (`response` and `finder` in this example) as parameters to your method.
Poniard will introspect the method before calling, and ensure that the correct
values are passed. These values will for the most part be the same objects you
normally deal with in Rails (`session`, `flash`, etc...).

The following controller renders the default index template, setting the
instance variables `@message`.

    module Controller
      class Registration
        def index(response)
          response.default message: "hello"
        end
      end
    end

This is more explicit than traditional controllers in two ways: passing
variables to the template is done with an explicit method call rather than
instance variable assignment, and dependencies that would normally be made
available by a superclass are passed in as parameters to the method.

Wiring this controller into your application is a one-liner in your normal
controller definition.

    class RegistrationsController < ApplicationController
      include Poniard::Controller

      provided_by Controller::Registration
    end

You can mix and match traditional and poniard styles. Some actions can be
implemented in the normal controller, others can be provided by an injectable
one.

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

### Sources

Poniard knows about all the standard controller objects such as `response`,
`session` and `flash`. You then layer your own domain specific definitions on
top by creating **sources**:

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

Wire this up in the `provided_by` call:

    provided_by Controller::Registration, sources: [
      Source::Registration
    ]

You can specify as many sources as you like, making it easy to reuse logic
across controllers.

Testing
-------

Set up a common injector for the scope of your controller that knows about
common sources that all tests require (such as `response`). Add extra required
sources on a per test basis (`finder` in the below example).

    require 'poniard/injector'
    require 'controller/registration'

    describe Controller::Registration do
      let(:response) { double("Poniard::ControllerSource") }
      let(:injector) { Poniard::Injector.new([OpenStruct.new(
        response: response.as_null_object
      )]) }

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

Techniques
----------

### Built-in sources

Undocumented, but it is a pretty straight-forward mapping to Rails objects with
the exception of `response`. The code is in `lib/poniard/controller_source.rb`.

### Layouts

If you implement a `layout` method in your controller, it will be used to
select a layout for the controller. This is equivalent to adding a custom
`layout` method to a standard controller.

### Mime types

The Rails `respond_with` API is not very OO, so is hard to test in isolation.
Poniard provides a wrapper that allows you to provide a response object that is
much easier to work with.

    module Controller
      class Registration
        def index(response, finder)
          response.respond_with RegistrationsIndexResponse, finder.all
        end

        RegistrationsIndexResponse = Struct.new(:registrations) do
          def html(response)
            response.default registrations: registrations
          end

          def json(response)
            response.render json: registrations.to_json
          end
        end
      end
    end

### Authorization

Poniard sources can raise exceptions to indicate authorization failure, which
can then be handled in a standard manner using `rescue_from`.

    module Source
      class Admin
        def current_organiser(session)
          Organiser.find_by_id(session[:organiser_id])
        end

        def authorized_organiser(current_organiser)
          current_organiser || raise(ResponseException::Unauthorized)
        end
      end
    end

This can be slightly weird if the method you are authorizing does not actually
need to interact with the organiser, since it will have a method parameter that
is never used.

    RSpec::Matchers.define :have_param do |attribute|
      match do |obj|
        obj.parameters.map(&:last).include?(attribute)
      end
    end

    def instance_method(name)
      described_class.new.method(name)
    end

    it 'requires authorization' do
      instance_method(:index).should have_param(:authorized_organiser)
    end

Developing
----------

### Status

Experimental. I've backported an existing app, added minor new features, and it
was a pleasant experience. It needs a lot more usage before the API stabilizes,
or it is even proved to be useful.

### Compatibility

Requires 1.9, should be easy to backport to 1.8 if anyone is interested. Use
1.9 style hashes and probably relies on `methods` calls returning symbols
rather than strings.

## Support

Make a [new github issue](https://github.com/xaviershay/poniard/issues/new).

## Contributing

Fork and patch! Please update the README and other documentation if you add
features.
