# Declarative content-type and size checks for ActiveStorage attachments.
#
#   validates_attachments :photos, content_types: %w[image/png image/jpeg], max_size: 10.megabytes
module AttachmentValidation
  extend ActiveSupport::Concern

  IMAGE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  DOCUMENT_TYPES = %w[application/pdf].freeze

  class_methods do
    def validates_attachments(name, content_types:, max_size:)
      type_label = content_types.map { |type| type.split("/").last.upcase }.to_sentence(two_words_connector: " or ", last_word_connector: ", or ")
      size_label = ActiveSupport::NumberHelper.number_to_human_size(max_size)

      validate do
        attachments = public_send(name)
        next unless attachments.attached?

        attachments.each do |attachment|
          unless content_types.include?(attachment.content_type)
            errors.add(name, "must be #{type_label} files")
            break
          end
        end

        if attachments.any? { |attachment| attachment.byte_size > max_size }
          errors.add(name, "must be smaller than #{size_label} each")
        end
      end
    end
  end
end
