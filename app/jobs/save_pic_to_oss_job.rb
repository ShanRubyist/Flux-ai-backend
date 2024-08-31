class SavePicToOssJob < ApplicationJob
  queue_as :default

  def perform(args)
    save_to_db(args)
  end

  private

  def save_to_db(h)
    user = h.fetch(:user)
    model_name = h.fetch(:model_name)
    aspect_ratio = h.fetch(:aspect_ratio)
    prompt = h.fetch(:prompt) { nil }
    data = h.fetch(:data) { {} }
    output = data.fetch("output")
    predict_id = data.fetch("id")
    if data.fetch('status') == 'succeeded'
      cost_credits =
        case model_name
        when nil
          1
        when 'black-forest-labs/flux-schnell'
          1
        when 'black-forest-labs/flux-dev'
          10
        when 'black-forest-labs/flux-pro'
          20
        end
    else
      cost_credits = 0
    end

    user
      .replicated_calls
      .create_with(data: data, output: output, prompt: prompt, aspect_ratio: aspect_ratio, cost_credits: cost_credits, model: model_name)
      .find_or_create_by(predict_id: predict_id)

    require 'open-uri'
    if output.is_a?(Array)
      image = output.first
    else
      image = output
    end

    user
      .replicated_calls
      .find_by(predict_id: predict_id)
      .image
      .attach(io: URI.open(image), filename: URI(image).path.split('/').last) unless image.empty?

  rescue => e
    puts e
  end

end
