class CustomFailureApp < Devise::FailureApp
  def respond
    if request.format == :turbo_stream
      redirect
    else
      super
    end
  end
end
