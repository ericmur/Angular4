class Api::DocytBot::V2::DocumentFieldValueSerializer < ActiveModel::Serializer
  attributes :speech_output

  def speech_output
    { "type" => "SSML", "ssml" => "Your Driver's License number is <say-as interpret-as='spell-out'>#{number}</say-as>" }
  end
end
