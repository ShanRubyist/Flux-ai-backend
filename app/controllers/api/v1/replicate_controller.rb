class Api::V1::ReplicateController < UsageController
  # rescue_from RuntimeError do |e|
  # render json: { error: e }.to_json, status: 500
  # end

  before_action :authenticate_user!

  def predict
    prompt = params['prompt']
    raise 'prompt can not be empty' unless prompt.present?

    model_name = params['model'] || 'black-forest-labs/flux-schnell'
    model = Replicate.client.retrieve_model(model_name)
    version = model.latest_version

    begin
      # webhook_url = "https://" + ENV.fetch("HOST") + "/replicate/webhook"
      prediction = version.predict(prompt: prompt)
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
      save_to_db({ params: params, data: data })
    end
  end

  private

  def save_to_db(h)
    params = h.fetch(:params) { {} }
    prompt = params.fetch(:prompt)
    data = h.fetch(:data) { {} }
    output = data.fetch("output")
    predict_id = data.fetch("id")

    current_user
      .replicated_calls
      .create_with(data: data, output: output, prompt: prompt)
      .find_or_create_by(predict_id: predict_id)
  end
end
