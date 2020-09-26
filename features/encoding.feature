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

    @bdrates_x265
    Examples: x265
      | flag                      | encoder | worse_better_same |
      | no-cutree=1               | x265    | worse             |
      | aq-mode=1:aq-strength=2   | x265    | better            |

    @bdrates_aomenc
    Examples: aomenc
      | flag                      | encoder | worse_better_same |
      | --min-partition-size=128  | aomenc  | worse             |
      | --enable-cdef=0           | aomenc  | better            |

    @bdrates_svt-av1
    Examples: svt-av1
      | flag                      | encoder | worse_better_same |
      | --film-grain 50           | svt-av1 | worse             |
      | --cdef-level 5            | svt-av1 | better            |
