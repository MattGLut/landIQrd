class ConversationsController < ApplicationController
  def index
    authorize Conversation
    @conversations = policy_scope(Conversation)
                       .includes(:participants, :work_order, :messages)
                       .order(updated_at: :desc)
  end

  def show
    @conversation = Conversation.find(params[:id])
    authorize @conversation
    @messages = @conversation.messages.includes(:author).order(:created_at)
    @message = @conversation.messages.new
  end

  def create
    if params[:work_order_id].present?
      work_order = WorkOrder.find(params[:work_order_id])
      authorize work_order, :show?
      @conversation = Conversation.for_work_order!(work_order)
    elsif params[:recipient_id].present?
      recipient = User.find(params[:recipient_id])
      @conversation = Conversation.direct_between!(current_user, recipient)
      authorize @conversation
    else
      skip_authorization
      return redirect_to conversations_path, alert: "Could not start that conversation."
    end

    redirect_to @conversation
  end
end
