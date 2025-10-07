# frozen_string_literal: true

module Search
  class EmbeddingService
    EMBEDDING_MODEL = "text-embedding-3-small"
    EMBEDDING_DIMENSIONS = 1536

    class << self
      # Generate embedding for a single text
      def embed(text)
        return nil if text.blank?

        normalized_text = normalize_text(text)
        return nil if normalized_text.blank?

        begin
          ensure_configured!
          result = RubyLLM.embed(normalized_text)

          # RubyLLM returns an Embedding object with a vectors method
          result.respond_to?(:vectors) ? result.vectors : nil
        rescue StandardError => e
          Rails.logger.error("Embedding generation failed: #{e.message}")
          Rails.logger.error(e.backtrace.first(5).join("\n"))
          nil
        end
      end

      # Generate embeddings for multiple texts in batch
      def embed_batch(texts)
        return [] if texts.empty?

        normalized_texts = texts.map { |text| normalize_text(text) }.compact
        return [] if normalized_texts.empty?

        begin
          ensure_configured!

          # Pass array to RubyLLM for batch processing (more efficient)
          result = RubyLLM.embed(normalized_texts)
          result.respond_to?(:vectors) ? result.vectors : []
        rescue StandardError => e
          Rails.logger.error("Batch embedding generation failed: #{e.message}")
          Rails.logger.error(e.backtrace.first(5).join("\n"))
          []
        end
      end

      # Generate embeddings for multiple cards in batch
      def embed_cards_batch(cards)
        return [] if cards.empty?

        texts = cards.map { |card| card_to_text(card) }
        embed_batch(texts)
      end

      # Generate embedding for a card based on its attributes
      def embed_card(card)
        text = card_to_text(card)
        embed(text)
      end

      # Generate embedding for card document (from hash)
      def embed_card_document(card_doc)
        text = card_document_to_text(card_doc)
        embed(text)
      end

      private

      def ensure_configured!
        return if @configured

        RubyLLM.configure do |config|
          config.openai_api_key = ENV.fetch("OPENAI_API_KEY")
        end
        @configured = true
      rescue KeyError => e
        Rails.logger.error("OPENAI_API_KEY environment variable not set")
        raise
      end

      # Convert card object to searchable text
      # Uses natural language format for better semantic embedding quality
      def card_to_text(card)
        parts = []

        # Start with card name and type in natural format
        if card.name.present? && card.type_line.present?
          parts << "#{card.name} is a #{card.type_line}."
        elsif card.name.present?
          parts << card.name
        end

        # Add oracle text as-is (already in natural language)
        parts << card.oracle_text if card.oracle_text.present?

        # For multi-faced cards, describe each face naturally
        if card.card_faces.any?
          card.card_faces.each do |face|
            face_parts = []
            if face.name.present? && face.type_line.present?
              face_parts << "#{face.name} is a #{face.type_line}."
            elsif face.name.present?
              face_parts << face.name
            end
            face_parts << face.oracle_text if face.oracle_text.present?
            parts << face_parts.join(" ") if face_parts.any?
          end
        end

        # Add keywords in natural language
        if card.keywords.present? && card.keywords.any?
          parts << "This card has #{card.keywords.join(", ")}."
        end

        # Add color identity for semantic context
        if card.color_identity.present? && card.color_identity.any?
          color_names = card.color_identity.map { |c|
            case c
            when "W" then "white"
            when "U" then "blue"
            when "B" then "black"
            when "R" then "red"
            when "G" then "green"
            else c
            end
          }
          parts << "Color identity: #{color_names.join(", ")}."
        end

        parts.join(" ")
      end

      # Convert card document hash to searchable text
      # Uses natural language format for better semantic embedding quality
      def card_document_to_text(doc)
        parts = []

        # Start with card name and type in natural format
        if doc[:name].present? && doc[:type_line].present?
          parts << "#{doc[:name]} is a #{doc[:type_line]}."
        elsif doc[:name].present?
          parts << doc[:name]
        end

        # Add oracle text as-is
        parts << doc[:oracle_text] if doc[:oracle_text].present?

        # For multi-faced cards, describe each face naturally
        if doc[:card_faces]&.any?
          doc[:card_faces].each do |face|
            face_parts = []
            if face[:name].present? && face[:type_line].present?
              face_parts << "#{face[:name]} is a #{face[:type_line]}."
            elsif face[:name].present?
              face_parts << face[:name]
            end
            face_parts << face[:oracle_text] if face[:oracle_text].present?
            parts << face_parts.join(" ") if face_parts.any?
          end
        end

        # Add keywords in natural language
        if doc[:keywords]&.any?
          parts << "This card has #{doc[:keywords].join(", ")}."
        end

        # Add color identity for semantic context
        if doc[:color_identity].present? && doc[:color_identity].any?
          color_names = doc[:color_identity].map { |c|
            case c
            when "W" then "white"
            when "U" then "blue"
            when "B" then "black"
            when "R" then "red"
            when "G" then "green"
            else c
            end
          }
          parts << "Color identity: #{color_names.join(", ")}."
        end

        parts.join(" ")
      end

      # Normalize text for embedding
      def normalize_text(text)
        return nil if text.blank?

        # Remove excessive whitespace and newlines
        normalized = text.gsub(/\s+/, " ").strip

        # Truncate if too long (model has token limits)
        # text-embedding-3-small supports 8191 tokens, roughly 32k characters
        # We'll be conservative and limit to 8000 characters
        normalized = normalized[0...8000] if normalized.length > 8000

        normalized
      end
    end
  end
end
