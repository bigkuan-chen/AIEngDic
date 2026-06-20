feature_spec:
  project_name: "AI WordPilot"
  feature_name: "智慧複習"
  feature_version: "1.0.0"

  goal: >
    只針對使用者加入「我的單字」的收藏內容建立複習題。
    系統每次從收藏單字中選擇待複習單字，
    以加權隨機方式避免短時間內一直重複相同單字，
    同時提高答錯單字、較久未複習單字及不熟悉單字的出現機率。

  core_principles:
    - "只有加入我的單字的內容可以進入複習"
    - "未收藏單字不得出現在複習題中"
    - "選題採加權隨機，不採完全隨機"
    - "最近出現過的單字降低抽中機率"
    - "答錯較多的單字提高抽中機率"
    - "長時間未複習的單字提高抽中機率"
    - "每次複習盡量涵蓋不同單字"
    - "同一單字可以用不同題型重複學習"
    - "題目與答案優先使用收藏時已儲存的資料"
    - "不應每一題都呼叫 LLM"

scope:
  included:
    - "從我的單字中建立複習"
    - "加權隨機選擇單字"
    - "避免短時間重複"
    - "多種複習題型"
    - "記錄答題結果"
    - "更新熟悉度"
    - "安排下次複習"
    - "顯示本次複習結果"
    - "離線使用已產生的題目"

  excluded:
    - "複習未收藏單字"
    - "社群排行榜"
    - "雲端同步"
    - "多人共用單字清單"
    - "語音發音評分"
    - "完整 FSRS 演算法"
    - "每題即時呼叫 LLM"

navigation:
  entry_points:
    my_words_screen:
      button:
        label: "開始智慧複習"
        icon: "school_outlined"
        enabled_when: "我的單字數量 >= 1"

    home_screen:
      optional_card:
        title: "今日複習"
        fields:
          - "今日待複習數"
          - "最近正確率"
        button: "開始複習"

  routes:
    review_setup:
      path: "/review/setup"
      screen: "ReviewSetupScreen"

    review_session:
      path: "/review/session"
      screen: "ReviewSessionScreen"

    review_result:
      path: "/review/result"
      screen: "ReviewResultScreen"

screens:
  review_setup_screen:
    id: "UI-REVIEW-01"
    name: "複習設定"

    components:
      available_word_count:
        type: "Text"
        format: "我的單字：{count} 個"

      question_count_selector:
        type: "SegmentedButton"
        label: "本次複習題數"
        options:
          - 5
          - 10
          - 15
          - 20
        default: 10

      review_mode_selector:
        type: "RadioGroup"
        label: "複習模式"
        options:
          smart:
            label: "智慧選題"
            description: "優先抽選較久未複習、答錯較多及不熟悉單字"
          random:
            label: "隨機複習"
            description: "從我的單字隨機選取，但仍避免近期重複"
          difficult:
            label: "加強弱項"
            description: "優先選擇錯誤率較高的單字"

        default: "smart"

      question_type_selector:
        type: "CheckboxGroup"
        label: "題型"
        minimum_selected: 1
        default_selected:
          - "en_to_zh"
          - "zh_to_en"
          - "context_choice"
          - "similar_word_choice"

      start_button:
        type: "FilledButton"
        label: "開始複習"
        action: "createReviewSession"

    validation:
      - "我的單字為空時不可開始複習"
      - "至少選擇一種題型"
      - "題數不得小於 1"
      - "若收藏單字少於題數，允許同一單字以不同題型再次出現"
      - "同一單字不可連續出現"

  review_session_screen:
    id: "UI-REVIEW-02"
    name: "智慧複習"

    app_bar:
      title: "智慧複習"
      show_progress: true
      progress_format: "{currentQuestion}/{totalQuestions}"
      close_button:
        confirmation_required: true
        confirmation_message: "要結束本次複習嗎？目前進度將會保留。"

    components:
      progress_bar:
        type: "LinearProgressIndicator"

      question_type_label:
        type: "Chip"
        examples:
          - "英翻中"
          - "中翻英"
          - "情境選字"
          - "相似字辨識"

      question_area:
        type: "Card"

      answer_area:
        type: "Dynamic"
        based_on_question_type: true

      submit_button:
        label: "確認答案"
        enabled_when: "使用者已選擇或輸入答案"

      feedback_panel:
        visible_after_submit: true
        fields:
          - "答對或答錯"
          - "正確答案"
          - "中文解釋"
          - "例句"
          - "錯誤原因"
          - "相似字差異"

      self_rating:
        visible_after_submit: true
        label: "你覺得這個單字如何？"
        options:
          forgot:
            label: "忘記了"
            score: 0
          hard:
            label: "有點難"
            score: 1
          good:
            label: "記得"
            score: 2
          easy:
            label: "很簡單"
            score: 3

      next_button:
        label: "下一題"
        action: "submitReviewResultAndContinue"

  review_result_screen:
    id: "UI-REVIEW-03"
    name: "複習結果"

    components:
      summary:
        fields:
          - "完成題數"
          - "答對題數"
          - "答錯題數"
          - "正確率"
          - "複習單字數"
          - "平均答題時間"

      difficult_words:
        title: "需要加強"
        source: "本次答錯或評為忘記、有點難的單字"
        item_fields:
          - "word"
          - "translationZhTw"
          - "wrongCount"
          - "nextReviewAt"

      mastered_words:
        title: "表現良好"
        source: "本次答對且評為記得或很簡單的單字"

      actions:
        review_wrong_answers:
          label: "再複習錯題"
          behavior: >
            建立只包含本次答錯單字的新複習 Session，
            但同一單字仍不得連續出現。

        return_to_my_words:
          label: "回到我的單字"

        finish:
          label: "完成"

question_types:
  en_to_zh:
    id: "QT-01"
    name: "英文選中文"
    difficulty: "easy"

    question_format:
      prompt: "請選出最適合的中文意思"
      content: "{word}"

    answer_format:
      type: "multiple_choice"
      option_count: 4

    correct_answer_source:
      field: "primaryTranslationZhTw"

    distractor_source:
      priority:
        - "其他收藏單字的中文意思"
        - "同詞性的收藏單字"
        - "已儲存的相似單字意思"

    validation:
      - "四個選項不得重複"
      - "錯誤選項不可與正確答案過度相近"
      - "正確答案位置必須隨機"

  zh_to_en:
    id: "QT-02"
    name: "中文選英文"
    difficulty: "medium"

    question_format:
      prompt: "請選出最適合的英文單字"
      content: "{primaryTranslationZhTw}"

    answer_format:
      type: "multiple_choice"
      option_count: 4

    correct_answer_source:
      field: "word"

    distractor_source:
      priority:
        - "其他收藏單字"
        - "相似單字"
        - "相同詞性的收藏單字"

    validation:
      - "錯誤選項不得包含正確答案的大小寫變形"
      - "正確答案位置必須隨機"

  spelling_input:
    id: "QT-03"
    name: "拼字輸入"
    difficulty: "medium"
    optional_for_mvp: true

    question_format:
      prompt: "請輸入英文單字"
      content: "{primaryTranslationZhTw}"

    answer_format:
      type: "text_input"

    answer_validation:
      ignore_case: true
      trim_whitespace: true
      allow_minor_punctuation_difference: true
      spelling_tolerance:
        enabled: false

  context_choice:
    id: "QT-04"
    name: "情境選字"
    difficulty: "medium"

    question_format:
      prompt: "哪個單字最適合填入句子？"
      content: "{exampleSentenceWithBlank}"

    answer_format:
      type: "multiple_choice"
      option_count: 4

    correct_answer_source:
      fields:
        - "word"
        - "savedEntry.examples"

    distractor_source:
      priority:
        - "similarWords"
        - "同詞性收藏單字"
        - "容易混淆單字"

    feedback:
      required_fields:
        - "正確句子"
        - "中文翻譯"
        - "為什麼使用這個單字"
        - "其他選項不適合的原因"

  similar_word_choice:
    id: "QT-05"
    name: "相似字辨識"
    difficulty: "hard"

    enabled_when:
      - "收藏單字具有 similarWords"
      - "或收藏過單字比較資料"

    question_format:
      prompt: "根據情境選出最自然的單字"
      content: "{contextZhTwOrSentence}"

    answer_format:
      type: "multiple_choice"
      option_count:
        minimum: 2
        maximum: 4

    correct_answer_source:
      fields:
        - "comparison.keyDifference"
        - "comparison.usageContext"
        - "comparison.example"

    feedback:
      required_fields:
        - "推薦單字"
        - "核心差異"
        - "常見搭配"
        - "是否可以互換"

  flashcard:
    id: "QT-06"
    name: "單字卡"
    difficulty: "easy"
    optional_for_mvp: true

    front:
      random_choice:
        - "word"
        - "primaryTranslationZhTw"
        - "exampleSentenceWithBlank"

    back:
      fields:
        - "word"
        - "phonetic"
        - "primaryTranslationZhTw"
        - "definitionEn"
        - "example"

    answer_mode:
      type: "self_rating_only"

review_session_creation:
  input:
    fields:
      - "favoriteWords"
      - "reviewItems"
      - "recentReviewHistory"
      - "selectedQuestionCount"
      - "selectedQuestionTypes"
      - "reviewMode"

  output:
    type: "ReviewSession"

  steps:
    - "讀取我的單字清單"
    - "排除已被使用者停用複習的單字"
    - "計算每個單字的抽選權重"
    - "套用近期重複懲罰"
    - "依權重抽選不同單字"
    - "為每個單字選擇適合題型"
    - "重新排列題目，避免同一單字連續出現"
    - "建立 ReviewSession"
    - "保存本次 Session"

word_selection_algorithm:
  name: "Weighted Random Review Selection"
  purpose: >
    在保留隨機性的同時，提高需要複習的單字機率，
    並降低近期已重複出現單字的機率。

  eligibility:
    required:
      - "word 存在於 favorites.json"
      - "reviewEnabled == true"
    excluded:
      - "已從我的單字刪除"
      - "資料不完整且無法產生任何題型"

  weight_formula:
    expression: >
      finalWeight =
      baseWeight
      * overdueFactor
      * difficultyFactor
      * errorFactor
      * unfamiliarFactor
      * recentPenalty
      * sessionPenalty
      * randomFactor

  factors:
    baseWeight:
      default: 1.0

    overdueFactor:
      description: "距離上次複習越久，權重越高"
      rules:
        never_reviewed: 2.5
        overdue_more_than_30_days: 2.3
        overdue_14_to_30_days: 2.0
        overdue_7_to_13_days: 1.7
        overdue_3_to_6_days: 1.4
        overdue_1_to_2_days: 1.2
        reviewed_today: 0.35

    difficultyFactor:
      description: "系統評估難度越高，權重越高"
      formula: "1.0 + difficultyScore * 0.25"
      difficultyScore_range:
        minimum: 0
        maximum: 4

    errorFactor:
      description: "答錯比例越高，權重越高"
      formula: "1.0 + errorRate * 1.5"
      errorRate_formula: >
        wrongCount / max(reviewCount, 1)

    unfamiliarFactor:
      description: "熟悉程度越低，權重越高"
      rules:
        new: 1.8
        learning: 1.5
        familiar: 1.0
        mastered: 0.55

    recentPenalty:
      description: "近期已出現的單字降低權重"
      rules:
        appeared_in_last_question: 0.0
        appeared_in_last_3_questions: 0.1
        appeared_in_last_5_questions: 0.25
        appeared_in_previous_session: 0.55
        not_recently_seen: 1.0

    sessionPenalty:
      description: "同一 Session 中已出現越多次，權重越低"
      rules:
        appeared_0_times: 1.0
        appeared_1_time: 0.35
        appeared_2_times: 0.12
        appeared_3_or_more_times: 0.0

    randomFactor:
      description: "保留隨機性，避免每次順序完全相同"
      range:
        minimum: 0.85
        maximum: 1.15

  hard_constraints:
    - "同一單字不得連續出現"
    - "最近 3 題內原則上不得重複相同單字"
    - "收藏單字數量足夠時，同一 Session 每個單字最多出現 1 次"
    - "收藏單字不足時，同一單字可使用不同題型再次出現"
    - "同一單字在同一 Session 最多出現 2 次"
    - "同一題型不得連續出現超過 3 次"

  fallback_rules:
    when_favorite_count_less_than_question_count:
      behavior:
        - "先讓所有可用單字至少出現一次"
        - "第二輪才允許重複單字"
        - "第二次出現必須使用不同題型"
        - "同一單字前後至少間隔 3 題"

    when_only_one_favorite_word:
      behavior:
        - "允許建立複習"
        - "使用不同題型"
        - "題目數最多限制為可產生的題型數"
        - "顯示收藏更多單字可獲得更佳複習效果"

question_type_selection:
  strategy: "Weighted Question Type Selection"

  rules:
    new_word:
      preferred_types:
        en_to_zh: 0.45
        zh_to_en: 0.30
        context_choice: 0.15
        similar_word_choice: 0.10

    learning_word:
      preferred_types:
        en_to_zh: 0.20
        zh_to_en: 0.30
        context_choice: 0.30
        similar_word_choice: 0.20

    familiar_word:
      preferred_types:
        en_to_zh: 0.10
        zh_to_en: 0.25
        context_choice: 0.35
        similar_word_choice: 0.30

    mastered_word:
      preferred_types:
        en_to_zh: 0.05
        zh_to_en: 0.20
        context_choice: 0.35
        similar_word_choice: 0.40

  anti_repetition:
    - "同一單字第二次出現時必須切換題型"
    - "同一題型連續出現 3 次後，下一題強制切換"
    - "題型選擇只可從使用者設定為啟用的題型中抽選"

review_scoring:
  answer_result:
    correct:
      base_score: 1
    incorrect:
      base_score: 0

  self_rating_multiplier:
    forgot: 0.0
    hard: 0.65
    good: 1.0
    easy: 1.25

  final_performance_score:
    formula: >
      answerResultBaseScore * selfRatingMultiplier

  status_update:
    new_to_learning:
      condition: "完成第一次複習"

    learning_to_familiar:
      condition:
        - "最近 5 次正確率 >= 80%"
        - "連續答對 >= 3"

    familiar_to_mastered:
      condition:
        - "最近 10 次正確率 >= 90%"
        - "連續答對 >= 5"
        - "至少經過 14 天"

    downgrade:
      mastered_to_familiar:
        condition: "答錯 1 次"

      familiar_to_learning:
        condition:
          - "最近 3 次答錯 >= 2"

review_schedule:
  algorithm: "Simplified Spaced Repetition"

  rating_rules:
    forgot:
      next_interval:
        value: 1
        unit: "day"
      difficulty_change: 0.5
      reset_streak: true

    hard:
      next_interval_formula: "max(1, currentIntervalDays * 1.2)"
      difficulty_change: 0.2

    good:
      next_interval_formula: >
        max(2, currentIntervalDays * 2.0)
      difficulty_change: -0.1

    easy:
      next_interval_formula: >
        max(4, currentIntervalDays * 3.0)
      difficulty_change: -0.25

  interval_limits:
    minimum_days: 1
    maximum_days: 180

  initial_intervals:
    first_correct: 1
    second_correct: 3
    third_correct: 7
    fourth_correct: 14
    fifth_correct: 30

  incorrect_override:
    next_review_days: 1
    lapse_count_increment: 1

data_models:
  review_item:
    fields:
      id:
        type: "string"
        format: "UUID"

      favoriteWordId:
        type: "string"
        required: true

      normalizedWord:
        type: "string"
        required: true

      reviewEnabled:
        type: "boolean"
        default: true

      learningStatus:
        type: "string"
        enum:
          - "new"
          - "learning"
          - "familiar"
          - "mastered"
        default: "new"

      difficultyScore:
        type: "double"
        minimum: 0
        maximum: 4
        default: 2

      reviewCount:
        type: "integer"
        default: 0

      correctCount:
        type: "integer"
        default: 0

      wrongCount:
        type: "integer"
        default: 0

      streak:
        type: "integer"
        default: 0

      lapseCount:
        type: "integer"
        default: 0

      currentIntervalDays:
        type: "integer"
        default: 0

      lastReviewedAt:
        type: "ISO-8601 datetime|null"

      nextReviewAt:
        type: "ISO-8601 datetime|null"

      lastQuestionType:
        type: "string|null"

      recentQuestionTypes:
        type: "array<string>"
        maximum: 5

  review_session:
    fields:
      id:
        type: "string"
        format: "UUID"

      mode:
        type: "string"
        enum:
          - "smart"
          - "random"
          - "difficult"

      plannedQuestionCount:
        type: "integer"

      currentQuestionIndex:
        type: "integer"

      questions:
        type: "array<ReviewQuestion>"

      recentWordIds:
        type: "array<string>"
        maximum: 5

      startedAt:
        type: "ISO-8601 datetime"

      completedAt:
        type: "ISO-8601 datetime|null"

      status:
        type: "string"
        enum:
          - "created"
          - "in_progress"
          - "completed"
          - "abandoned"

  review_question:
    fields:
      id:
        type: "string"
        format: "UUID"

      reviewItemId:
        type: "string"

      favoriteWordId:
        type: "string"

      normalizedWord:
        type: "string"

      questionType:
        type: "string"
        enum:
          - "en_to_zh"
          - "zh_to_en"
          - "spelling_input"
          - "context_choice"
          - "similar_word_choice"
          - "flashcard"

      prompt:
        type: "string"

      questionContent:
        type: "string"

      options:
        type: "array<string>"

      correctAnswer:
        type: "string"

      explanation:
        type: "string"

      exampleEnglish:
        type: "string|null"

      exampleZhTw:
        type: "string|null"

      source:
        type: "string"
        enum:
          - "favorite_data"
          - "comparison_data"
          - "generated_and_cached"

  review_answer:
    fields:
      id:
        type: "string"
        format: "UUID"

      sessionId:
        type: "string"

      questionId:
        type: "string"

      reviewItemId:
        type: "string"

      userAnswer:
        type: "string|null"

      isCorrect:
        type: "boolean"

      selfRating:
        type: "string"
        enum:
          - "forgot"
          - "hard"
          - "good"
          - "easy"

      responseTimeMs:
        type: "integer"

      answeredAt:
        type: "ISO-8601 datetime"

      previousIntervalDays:
        type: "integer"

      nextIntervalDays:
        type: "integer"

local_storage:
  recommendation:
    mvp:
      favorites: "favorites.json"
      review_items: "review_items.json"
      review_sessions: "review_sessions.json"
      review_answers: "review_answers.json"

    production:
      preferred: "Drift + SQLite"
      reason:
        - "複習紀錄會持續增加"
        - "需要依日期查詢待複習單字"
        - "需要統計答對率"
        - "需要快速更新單一 ReviewItem"
        - "避免頻繁重寫大型 JSON"

  files:
    review_items.json:
      purpose:
        - "保存每個收藏單字的學習狀態"
        - "保存下次複習時間"
        - "保存答對與答錯統計"

    review_sessions.json:
      purpose:
        - "保存未完成與已完成 Session"
      retention:
        completed_sessions_days: 90

    review_answers.json:
      purpose:
        - "保存歷史答題結果"
      retention:
        strategy: "保留最近 1000 筆或最近 180 天"

favorite_integration:
  on_add_favorite:
    actions:
      - "建立 FavoriteWord"
      - "建立對應 ReviewItem"
      - "learningStatus 設為 new"
      - "nextReviewAt 設為目前時間"
      - "reviewEnabled 預設為 true"

  on_remove_favorite:
    actions:
      - "從 favorites 移除單字"
      - "刪除或停用對應 ReviewItem"
      - "未來 Session 不得再抽到該單字"
      - "歷史 ReviewAnswer 可以保留供統計"

  on_readd_favorite:
    behavior:
      recommendation: "恢復舊的 ReviewItem"
      rule:
        - "如果存在停用紀錄，恢復 reviewEnabled"
        - "保留原學習狀態"
        - "使用者可選擇重新開始"

question_generation:
  strategy:
    priority:
      - "使用收藏時儲存的字典資料"
      - "使用收藏時儲存的相似字與比較資料"
      - "使用本機已快取題目"
      - "資料不足時才呼叫 LLM"

  no_llm_required:
    question_types:
      - "en_to_zh"
      - "zh_to_en"
      - "基本拼字題"
      - "已有例句的填空題"

  llm_optional:
    use_cases:
      - "收藏資料沒有例句"
      - "需要新增情境選字題"
      - "需要重新產生錯誤選項"
      - "需要更新已使用多次的題目"

  generation_timing:
    recommended: "加入收藏時預先生成或第一次複習前批次生成"
    avoid: "答題畫面每題等待 LLM"

  generated_question_cache:
    maximum_questions_per_word:
      en_to_zh: 3
      zh_to_en: 3
      context_choice: 5
      similar_word_choice: 5

    reuse_rule:
      - "相同題目在最近 20 題內不得重複"
      - "使用超過 3 次後標記為需要更新"

review_modes:
  smart:
    selection:
      overdue_weight: "high"
      error_weight: "high"
      random_weight: "medium"
      recent_penalty: "high"

  random:
    selection:
      overdue_weight: "low"
      error_weight: "low"
      random_weight: "high"
      recent_penalty: "high"

  difficult:
    selection:
      overdue_weight: "medium"
      error_weight: "very_high"
      random_weight: "low"
      recent_penalty: "medium"

business_rules:
  - id: "BR-REVIEW-001"
    rule: "只有我的單字清單中的单字可以加入複習池。"

  - id: "BR-REVIEW-002"
    rule: "同一單字不得連續出現。"

  - id: "BR-REVIEW-003"
    rule: "當收藏數量足夠時，最近三題內不得重複同一單字。"

  - id: "BR-REVIEW-004"
    rule: "同一 Session 中，同一單字原則上只出現一次。"

  - id: "BR-REVIEW-005"
    rule: "若題數大於收藏單字數，可讓單字以不同題型再次出現。"

  - id: "BR-REVIEW-006"
    rule: "答錯單字不可立即在下一題再次出現，至少間隔兩題。"

  - id: "BR-REVIEW-007"
    rule: "答錯單字應提高未來 Session 的權重，而不是在目前 Session 立刻重複轟炸。"

  - id: "BR-REVIEW-008"
    rule: "已掌握單字仍可出現，但權重低於新單字與學習中單字。"

  - id: "BR-REVIEW-009"
    rule: "使用者刪除收藏後，該單字不得再產生新複習題。"

  - id: "BR-REVIEW-010"
    rule: "題目答案不得依賴即時網路才能判斷。"

  - id: "BR-REVIEW-011"
    rule: "選項順序每次必須重新隨機排列。"

  - id: "BR-REVIEW-012"
    rule: "題目選擇與答案檢查應在本機完成。"

anti_repeat_design:
  word_history_window:
    current_session:
      keep_last_words: 5

    previous_sessions:
      keep_last_sessions: 3
      keep_last_reviewed_words: 30

  penalties:
    last_question: 0.0
    last_3_questions: 0.1
    last_5_questions: 0.25
    previous_session: 0.55
    older_history: 1.0

  question_history:
    keep_last_question_ids: 20
    repeated_question_penalty: 0.0

  sequence_post_processing:
    enabled: true
    steps:
      - "完成加權抽選後檢查排列"
      - "若相同單字相鄰，與後方不同單字交換"
      - "若同一題型連續超過三題，重新排列"
      - "若無法避免，保留單字不連續為最高優先"

edge_cases:
  no_favorites:
    message: "尚未加入任何單字，請先將單字加入我的單字。"
    action_button:
      label: "前往查詢"
      route: "/dictionary"

  one_favorite:
    message: "目前只有一個收藏單字，題型會輪流變化。"
    max_questions: 4

  two_favorites:
    behavior:
      - "交替出題"
      - "禁止同一單字連續"
      - "切換題型"

  incomplete_favorite_data:
    behavior:
      - "只使用能產生的題型"
      - "必要時標記待補充資料"
      - "不得因單一單字資料不足中斷整個 Session"

  user_exits_early:
    behavior:
      - "保存已完成題目"
      - "未完成題目不計分"
      - "可選擇稍後繼續"

  favorite_deleted_during_session:
    behavior:
      - "目前題目可以完成"
      - "之後未出現的該單字題目從 Session 移除"

state_management:
  providers:
    review_pool_provider:
      responsibility:
        - "讀取收藏單字"
        - "建立可複習單字池"

    review_session_provider:
      responsibility:
        - "建立 Session"
        - "管理目前題目"
        - "避免重複單字"
        - "控制題型順序"

    review_progress_provider:
      responsibility:
        - "保存本次進度"
        - "計算正確率"
        - "產生結果摘要"

    review_repository_provider:
      responsibility:
        - "讀寫 ReviewItem"
        - "讀寫 ReviewSession"
        - "讀寫 ReviewAnswer"

  shared_state_rule: >
    我的單字頁、複習設定頁與複習畫面，
    必須使用同一份收藏與複習 Repository，
    不得各自建立獨立清單。

error_handling:
  load_favorites_failed:
    message: "無法讀取我的單字，請重新嘗試。"

  create_session_failed:
    message: "無法建立複習內容。"

  save_answer_failed:
    message: "答題結果暫時無法儲存。"
    behavior:
      - "先保留在記憶體"
      - "稍後重新寫入"

  malformed_question:
    behavior:
      - "跳過該題"
      - "補選另一個單字或題型"
      - "記錄錯誤但不顯示敏感資料"

testing:
  unit_tests:
    - "只從 Favorites 建立 Review Pool"
    - "已刪除收藏不會被選中"
    - "最近一題的單字權重為零"
    - "最近三題中的單字權重大幅降低"
    - "答錯率較高的單字權重較高"
    - "長時間未複習的單字權重較高"
    - "mastered 單字權重較低"
    - "同一單字不連續出現"
    - "題數大於單字數時切換題型"
    - "正確答案位置隨機"
    - "更新 ReviewItem 排程"

  widget_tests:
    - "我的單字為空時顯示提示"
    - "複習設定可以選擇題數"
    - "複習畫面顯示進度"
    - "提交答案後顯示解析"
    - "可以選擇忘記、有點難、記得、很簡單"
    - "完成後顯示結果摘要"

  integration_tests:
    - "加入收藏後可以立即進入複習池"
    - "完成 10 題複習並保存結果"
    - "重新開啟 App 後保留複習進度"
    - "答錯單字在下次 Session 的出現機率提高"
    - "同一 Session 不會連續出現同一單字"
    - "刪除收藏後不再出現"
    - "離線狀態可完成已有題目"

acceptance_criteria:
  - "所有複習題都來自我的單字清單。"
  - "同一單字不會連續出現。"
  - "收藏單字足夠時，同一 Session 盡量不重複單字。"
  - "收藏單字不足時，重複單字必須切換題型。"
  - "答錯較多的單字在後續複習中具有較高權重。"
  - "最近已複習的單字抽中機率明顯降低。"
  - "較久未複習的單字抽中機率提高。"
  - "完成答題後會更新熟悉度與下次複習日期。"
  - "使用者可以查看本次答對率與需要加強的單字。"
  - "複習過程不需要每題呼叫 LLM。"

implementation_phases:
  phase_1:
    name: "建立複習資料模型"
    tasks:
      - "建立 ReviewItem"
      - "建立 ReviewSession"
      - "建立 ReviewQuestion"
      - "建立 ReviewAnswer"
      - "收藏單字時自動建立 ReviewItem"

  phase_2:
    name: "實作選題演算法"
    tasks:
      - "建立可複習單字池"
      - "實作權重計算"
      - "實作近期重複懲罰"
      - "實作加權隨機抽選"
      - "實作題目順序重新排列"

  phase_3:
    name: "實作基本題型"
    tasks:
      - "英文選中文"
      - "中文選英文"
      - "情境選字"
      - "相似字辨識"
      - "錯誤選項產生"

  phase_4:
    name: "實作複習 UI"
    tasks:
      - "ReviewSetupScreen"
      - "ReviewSessionScreen"
      - "答案回饋"
      - "自我熟悉度評分"
      - "ReviewResultScreen"

  phase_5:
    name: "排程與統計"
    tasks:
      - "更新 ReviewItem"
      - "計算下次複習日期"
      - "顯示正確率"
      - "顯示需要加強單字"
      - "保存與恢復 Session"

  phase_6:
    name: "最佳化與測試"
    tasks:
      - "避免單字連續"
      - "避免題型連續"
      - "處理收藏不足"
      - "離線測試"
      - "大量答題紀錄效能測試"