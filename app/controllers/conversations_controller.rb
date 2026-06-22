class ConversationsController < ApplicationController
  def index
    authorize Conversation
    load_conversations
    load_selected_conversation if params[:conversation_id].present?
  end

  def show
    @conversation = Conversation.find(params[:id])
    authorize @conversation
    @conversation.conversation_participants.find_by(user: current_user)&.mark_read!
    load_conversations
    load_conversation_thread
    render :index
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

  private

  def load_conversations
    @conversations = policy_scope(Conversation)
                       .includes(:participants, :work_order, :messages, :conversation_participants)
                       .order(updated_at: :desc)
  end

  def load_selected_conversation
    @conversation = @conversations.find_by(id: params[:conversation_id])
    authorize @conversation if @conversation
    load_conversation_thread if @conversation
  end

  def load_conversation_thread
    @conversation.conversation_participants.find_by(user: current_user)&.mark_read!
    @messages = @conversation.messages.includes(:author).order(:created_at)
    @message = @conversation.messages.new
  end
end
