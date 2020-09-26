Feature: Encoding files

  Scenario Outline: Encoding files
    Given I want to encode a video
    When I encode the video with <encoder>
    Then the output file will be encoded with <encoder_output>

    Examples: encoders
      | encoder | encoder_output |
      | x265    | hevc           |
      | aomenc  | av1            |
      | svt-av1 | av1            |
