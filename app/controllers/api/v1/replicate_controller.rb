class Api::V1::ReplicateController < UsageController
  # rescue_from RuntimeError do |e|
  # render json: { error: e }.to_json, status: 500
  # end

  def predict
    prompt = params['prompt']
    raise 'prompt can not be empty' unless prompt.present?

    aspect_ratio = params['aspect_ratio'] || '1:1'

    model_name = params['model'] || 'black-forest-labs/flux-schnell'
    model = Replicate.client.retrieve_model(model_name)
    version = model.latest_version

    begin
      # webhook_url = "https://" + ENV.fetch("HOST") + "/replicate/webhook"
      prediction = version.predict(prompt: prompt, aspect_ratio: aspect_ratio)
      data = prediction.refetch

      until prediction.finished? do
        sleep 1
        data = prediction.refetch
      end

      # rails 'prediction failed' if prediction.failed? || prediction.canceled?
      render json: {
        images: prediction.output
      }

    ensure
      save_to_db({ model_name: model_name, aspect_ratio: aspect_ratio, params: params, data: data })
    end
  end

  def generated_images
    replicated_calls = current_user
                         .replicated_calls
                         .where("replicated_calls.data->>'status' = ?", 'succeeded')
                         .order("created_at desc")

    result = replicated_calls.map do |item|
      {
        image: (url_for(item.image) rescue nil),
        prompt: item.prompt,
        created_at: item.created_at,
        aspect_ratio: item.aspect_ratio,
        cost_credits: item.cost_credits,
        model: item.model
      }
    end

    render json: result
  end

  private

  def save_to_db(h)
    model_name = h.fetch(:model_name)
    aspect_ratio = h.fetch(:aspect_ratio)
    params = h.fetch(:params) { {} }
    prompt = params.fetch(:prompt)
    data = h.fetch(:data) { {} }
    output = data.fetch("output")
    predict_id = data.fetch("id")
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

    current_user
      .replicated_calls
      .create_with(data: data, output: output, prompt: prompt, aspect_ratio: aspect_ratio, cost_credits: cost_credits, model: model_name)
      .find_or_create_by(predict_id: predict_id)

    require 'open-uri'
    current_user
      .replicated_calls
      .find_by(predict_id: predict_id)
      .image
      .attach(io: URI.open(output.first), filename: URI(output.first).path.split('/').last) unless output.first.empty?

  rescue => e
    puts e
  end
end
