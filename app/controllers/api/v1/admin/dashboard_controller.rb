class Api::V1::Admin::DashboardController < Api::V1::AdminController

  def statistics_info
    total_users = User.all.size
    total_paid_users = -1
    total_generated_user = User.joins(:replicated_calls).distinct.count
    total_images = ReplicatedCall.all.size
    total_failed_images = ReplicatedCall.where("replicated_calls.data->>'status' != ?", 'succeeded').size
    total_paid_dollar = -1
    total_paid_credits = 0
    total_cost_dollar = -1
    total_cost_credits = ReplicatedCall.where("replicated_calls.data->>'status' = ?", 'succeeded').sum(:cost_credits)
    total_left_dollar = -1
    total_left_credits = total_paid_credits - total_cost_credits

    today_newly_users = User.where("DATE(created_at) = ?", Date.today).count
    today_paid_users = -1
    today_generated_users = User.joins(:replicated_calls)
                                .where(replicated_calls: { created_at: Time.current.beginning_of_day..Time.current.end_of_day })
                                .distinct
                                .count
    today_images = ReplicatedCall.where(created_at: Time.current.beginning_of_day..Time.current.end_of_day).count
    today_failed_images = ReplicatedCall
                            .where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
                            .where("replicated_calls.data->>'status' != ?", 'succeeded')
                            .count
    today_paid_dollar = -1
    today_paid_credits = -1
    today_cost_dollar = -1
    today_cost_credits = ReplicatedCall
                           .where(created_at: Time.current.beginning_of_day..Time.current.end_of_day)
                           .where("replicated_calls.data->>'status' = ?", 'succeeded')
                           .sum(:cost_credits)

    freeium_total_credits = total_users * (ENV.fetch('FREEMIUM_CREDITS') { 0 }).to_i
    freeium_cost_credits = total_cost_credits
    freeium_left_credits = freeium_total_credits - freeium_cost_credits
    freeium_run_out_users = -1
    # User.joins(:replicated_calls)
    #                          .where("replicated_calls.data->>'status' = ?", 'succeeded')
    #                          .group('users.id')
    #                          .having('COUNT(*) >= ?', 0)
    #                       .select("users.id, users.email, COUNT(*) as successful_call_count")

    user_top_paid_dollar = -1
    user_top_paid_credits = -1
    user_top_cost_dollar = -1
    user_top_cost_credits = User.joins(:replicated_calls)
                                .group("users.id")
                                .select("users.id, sum(cost_credits) as cost_credits")
                                .order('cost_credits desc')
                                .limit(1)
                                .first
                                .cost_credits

    user_top_generated_images = User.joins(:replicated_calls)
                                    .group("users.id")
                                    .select("users.id, users.email, COUNT(*) as call_count")
                                    .order("call_count desc")
                                    .limit(1)
                                    .first.call_count
    render json: {
      total_users: total_users,
      total_paid_users: total_paid_users,
      total_generated_user: total_generated_user,
      total_images: total_images,
      total_failed_images: total_failed_images,
      total_paid_dollar: total_paid_dollar,
      total_paid_credits: total_paid_credits,
      total_cost_dollar: total_cost_dollar,
      total_cost_credits: total_cost_credits,
      total_left_dollar: total_left_dollar,
      total_left_credits: total_left_credits,
      today_newly_users: today_newly_users,
      today_paid_users: today_paid_users,
      today_generated_users: today_generated_users,
      today_images: today_images,
      today_failed_images: today_failed_images,
      today_paid_dollar: today_paid_dollar,
      today_paid_credits: today_paid_credits,
      today_cost_dollar: today_cost_dollar,
      today_cost_credits: today_cost_credits,
      freeium_total_credits: freeium_total_credits,
      freeium_cost_credits: freeium_cost_credits,
      freeium_left_credits: freeium_left_credits,
      freeium_run_out_users: freeium_run_out_users,
      user_top_paid_dollar: user_top_paid_dollar,
      user_top_paid_credits: user_top_paid_credits,
      user_top_cost_dollar: user_top_cost_dollar,
      user_top_cost_credits: user_top_cost_credits,
      user_top_generated_images: user_top_generated_images
    }.to_json
  end

  def generated_images
    params[:page] ||= 1
    params[:per] ||= 20

    replicated_calls = ReplicatedCall
                         .order("created_at desc")
                         .page(params[:page].to_i)
                         .per(params[:per].to_i)

    result = replicated_calls.map do |item|
      {
        image: (url_for(item.image) rescue nil),
        prompt: item.prompt,
        created_at: item.created_at,
        aspect_ratio: item.aspect_ratio,
        cost_credits: item.cost_credits,
        model: item.model&.sub("black-forest-labs/", ''),
        status: item.data.fetch('status') { nil }
      }
    end

    render json: {
      total: replicated_calls.total_count,
      histories: result
    }
  end

end





