Feature: Run

  @encoders
  Scenario Outline: Encoders
    Given I want to encode a video
    When I encode the video with <encoder>
    Then the output file will be encoded with <encoder_output>

    Examples: Encoders
      | encoder | encoder_output |
      | x265    | hevc           |
      | aomenc  | av1            |
      | svt-av1 | av1            |

  @bdrates
  Scenario Outline: BD Rate
    Given I want to calculate bd rate of <flag>
    When I encode the video with <encoder>
    Then there should be a csv file with vmaf bd rate <worse_better_same> than 0

    Examples: Flags
      | flag                    | encoder | worse_better_same |
      | aq-mode=1:aq-strength=3 | x265    | worse             |
      | rc-lookahead=80         | x265    | better            |
