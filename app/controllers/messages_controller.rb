class MessagesController < ApplicationController
  def create
    @conversation = Conversation.find(params[:conversation_id])
    @message = @conversation.messages.new(message_params)
    @message.author = current_user
    authorize @message

    if @message.save
      @conversation.touch
      Notifications::Deliver.new_message(@message, actor: current_user)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @conversation }
      end
    else
      @messages = @conversation.messages.includes(:author).order(:created_at)
      render "conversations/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:body, files: [])
  end
end
