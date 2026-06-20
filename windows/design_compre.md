feature_spec:
  project_name: "AI WordPilot"
  feature_name: "相似單字與單字比較"
  feature_version: "1.0.0"

  goal: >
    使用者查詢中文或英文後，除了顯示主要查詢結果，
    系統還要顯示與主要單字意思相近、但用法可能不同的英文單字。
    使用者點擊「比較單字」按鈕後，開啟新的比較 UI，
    比較主要單字與相似單字的意思、用法、搭配與例句。
    比較畫面中的每一個單字都可以個別加入或移除「我的單字」。

  scope:
    included:
      - "查詢結果回傳主要單字"
      - "查詢結果回傳最多 5 個相似單字"
      - "查詢主畫面顯示相似單字"
      - "比較單字按鈕"
      - "彈出單字比較 UI"
      - "比較 2 至 5 個單字"
      - "每個單字獨立收藏"
      - "收藏結果儲存於手機"
      - "已收藏狀態同步顯示"

    excluded:
      - "智慧複習"
      - "比較組收藏"
      - "使用者自行新增比較單字"
      - "雲端同步"
      - "登入帳號"
      - "發音評分"
      - "學習統計"

ui_flow:
  step_1:
    screen: "DictionaryScreen"
    action: "使用者輸入中文或英文"
    example_input: "完成一個困難任務"

  step_2:
    screen: "DictionaryScreen"
    action: "呼叫目前設定的 LLM"
    expected_primary_word: "accomplish"
    expected_similar_words:
      - "achieve"
      - "complete"
      - "fulfill"

  step_3:
    screen: "DictionaryScreen"
    action: "顯示主要單字結果與相似單字區塊"

  step_4:
    screen: "DictionaryScreen"
    action: "使用者點擊比較單字按鈕"

  step_5:
    screen: "WordComparisonModal"
    action: "彈出新的比較 UI"

  step_6:
    screen: "WordComparisonModal"
    action: "使用者查看單字差異，並個別收藏單字"

screens:
  dictionary_screen:
    id: "UI-01"
    name: "字典查詢主畫面"

    existing_components:
      - "查詢文字欄位"
      - "搜尋按鈕"
      - "主要單字結果"
      - "主要單字收藏按鈕"
      - "設定按鈕"
      - "我的單字按鈕"

    new_components:
      similar_words_section:
        type: "Card"
        id: "similarWordsSection"
        title: "相似單字"
        visible_when:
          - "查詢成功"
          - "similarWords 不為空"

        description:
          text: "這些單字意思相近，但使用情境可能不同。"

        word_display:
          type: "Wrap"
          item_component: "SimilarWordChip"
          max_display_count: 5

        compare_button:
          type: "FilledButton"
          id: "compareWordsButton"
          label: "比較單字"
          icon: "compare_arrows"
          enabled_when:
            - "主要單字存在"
            - "至少有 1 個相似單字"
          action: "openWordComparisonModal"

        empty_behavior:
          show_section: false

      similar_word_chip:
        type: "ActionChip"
        display_fields:
          - "word"
          - "shortTranslationZhTw"

        example:
          word: "achieve"
          shortTranslationZhTw: "達成目標"

        on_tap:
          action: "showSimilarWordPreview"

        optional_trailing_icon:
          icon: "info_outline"

    suggested_layout:
      order:
        - "SearchInput"
        - "PrimaryWordHeader"
        - "PrimaryMeanings"
        - "Examples"
        - "Collocations"
        - "SimilarWordsSection"
        - "AI Disclaimer"

    wireframe: |
      ┌───────────────────────────────────┐
      │ AI WordPilot            ⚙️   ☰    │
      ├───────────────────────────────────┤
      │ [輸入英文或中文             ] 🔍  │
      ├───────────────────────────────────┤
      │ accomplish              ☆         │
      │ /əˈkʌmplɪʃ/                       │
      │ verb                              │
      │ 完成、達成一項任務                  │
      │                                   │
      │ To succeed in completing something│
      │ difficult.                        │
      │                                   │
      │ Example                           │
      │ We accomplished the project.      │
      ├───────────────────────────────────┤
      │ 相似單字                           │
      │ 意思相近，但使用情境可能不同。       │
      │                                   │
      │ [achieve 達成] [complete 完成]      │
      │ [fulfill 履行]                     │
      │                                   │
      │            [ ⇄ 比較單字 ]          │
      └───────────────────────────────────┘

  similar_word_preview:
    id: "UI-01-A"
    name: "相似單字快速預覽"
    presentation: "ModalBottomSheet"
    optional_for_first_iteration: true

    trigger:
      source: "SimilarWordChip"
      action: "tap"

    content:
      - "英文單字"
      - "音標"
      - "詞性"
      - "簡短中文意思"
      - "與主要單字的關鍵差異"

    actions:
      full_lookup:
        label: "完整查詢"
        behavior:
          - "關閉 BottomSheet"
          - "將該相似字填入查詢欄"
          - "重新執行查詢"

      add_to_favorites:
        label_default: "加入我的單字"
        label_selected: "已加入我的單字"
        behavior: "toggleFavorite"

  word_comparison_modal:
    id: "UI-04"
    name: "比較單字"
    component_name: "WordComparisonModal"

    presentation:
      mobile: "FullScreenDialog"
      tablet: "Dialog"
      web: "LargeDialog"
      recommendation: >
        手機版建議使用 FullScreenDialog，而不是小型 AlertDialog。
        比較內容較多，需要完整高度和垂直捲動空間。

    open_method:
      flutter: "Navigator.push 或 showModalBottomSheet"
      recommended_flutter: "showModalBottomSheet"
      properties:
        isScrollControlled: true
        useSafeArea: true
        showDragHandle: true

    app_bar:
      title: "比較單字"
      close_button:
        icon: "close"
        action: "closeModal"

    header:
      title_template: "{primaryWord} 與相似單字"
      subtitle: "比較意思、使用情境與常見搭配"

    word_selector:
      type: "HorizontalScrollableChips"
      purpose: "顯示目前參與比較的單字"
      minimum_words: 2
      maximum_words: 5
      primary_word_removable: false
      similar_words_removable: true

      example:
        - "accomplish"
        - "achieve"
        - "complete"
        - "fulfill"

    summary_section:
      type: "Card"
      title: "快速理解"
      content_source: "comparison.quickSummary"

      example: |
        accomplish 強調完成一項需要努力的具體任務；
        achieve 強調達成目標或獲得成果；
        complete 表示把事情完整做完；
        fulfill 常用於履行責任、承諾或滿足需求。

    word_cards:
      type: "ListView"
      item_component: "ComparisonWordCard"
      order: "主要單字優先，其餘依 LLM 回傳順序"
      scroll_direction: "vertical"

    comparison_dimensions:
      display_mode: "GroupedComparisonSections"
      sections:
        - id: "core_meaning"
          title: "核心差異"
        - id: "usage"
          title: "適用情境"
        - id: "collocations"
          title: "常見搭配"
        - id: "examples"
          title: "例句比較"
        - id: "interchangeability"
          title: "是否可以互換"

    footer:
      disclaimer: "比較內容由 AI 產生，可能需要交叉確認。"

    wireframe: |
      ┌───────────────────────────────────┐
      │ ✕  比較單字                       │
      ├───────────────────────────────────┤
      │ [accomplish] [achieve] [complete] │
      │ [fulfill]                         │
      ├───────────────────────────────────┤
      │ 快速理解                           │
      │ accomplish：完成具體任務            │
      │ achieve：達成目標或成果              │
      │ complete：完整做完                  │
      │ fulfill：履行承諾或責任              │
      ├───────────────────────────────────┤
      │ accomplish                    ☆   │
      │ 完成一項需要努力的具體任務           │
      │ 常見搭配：accomplish a task         │
      │ 例句：We accomplished our mission. │
      │ [加入我的單字]                      │
      ├───────────────────────────────────┤
      │ achieve                       ★   │
      │ 達到目標或獲得成果                  │
      │ 常見搭配：achieve a goal            │
      │ 例句：She achieved her goal.       │
      │ [已加入我的單字]                    │
      └───────────────────────────────────┘

components:
  comparison_word_card:
    name: "ComparisonWordCard"
    type: "Card"

    displayed_fields:
      word:
        style: "headlineSmall"
      phonetic:
        style: "bodyMedium"
      part_of_speech:
        style: "LabelChip"
      translation_zh_tw:
        style: "titleMedium"
      key_difference:
        label: "核心差異"
      usage_context:
        label: "適用情境"
      common_collocations:
        label: "常見搭配"
        max_items: 3
      example:
        label: "例句"
        fields:
          - "english"
          - "traditionalChinese"
      interchangeability_note:
        label: "互換提醒"

    favorite_control:
      icon_button:
        not_favorite_icon: "star_border"
        favorite_icon: "star"
        tooltip_not_favorite: "加入我的單字"
        tooltip_favorite: "從我的單字移除"

      action_button:
        not_favorite_label: "加入我的單字"
        favorite_label: "已加入我的單字"
        not_favorite_icon: "bookmark_add_outlined"
        favorite_icon: "bookmark_added"

      behavior:
        action: "toggleFavorite"
        optimistic_update: true
        show_snackbar: true

      snackbar_messages:
        added: "{word} 已加入我的單字"
        removed: "{word} 已從我的單字移除"
        failed: "無法更新我的單字，請重新嘗試"

    favorite_state_source:
      repository: "FavoritesRepository"
      key: "normalizedWord"

data_models:
  dictionary_query_result:
    fields:
      query:
        type: "string"
        required: true

      primaryWord:
        type: "DictionaryWord"
        required: true

      similarWords:
        type: "array<SimilarWord>"
        minimum: 0
        maximum: 5

      comparison:
        type: "WordComparison"
        nullable: true

  dictionary_word:
    fields:
      word:
        type: "string"
        required: true

      normalizedWord:
        type: "string"
        required: true

      phonetic:
        type: "string|null"

      partOfSpeech:
        type: "string|null"

      translationZhTw:
        type: "string"
        required: true

      definitionEn:
        type: "string|null"

      examples:
        type: "array<DictionaryExample>"

      collocations:
        type: "array<Collocation>"

  similar_word:
    fields:
      word:
        type: "string"
        required: true

      normalizedWord:
        type: "string"
        required: true

      phonetic:
        type: "string|null"

      partOfSpeech:
        type: "string|null"

      shortTranslationZhTw:
        type: "string"
        required: true

      keyDifference:
        type: "string"
        required: true

      relationshipType:
        type: "string"
        enum:
          - "near_synonym"
          - "contextual_synonym"
          - "easily_confused"

  word_comparison:
    fields:
      title:
        type: "string"

      quickSummary:
        type: "string"
        required: true

      words:
        type: "array<ComparisonWord>"
        minimum: 2
        maximum: 5

      interchangeabilitySummary:
        type: "string|null"

  comparison_word:
    fields:
      word:
        type: "string"
        required: true

      normalizedWord:
        type: "string"
        required: true

      phonetic:
        type: "string|null"

      partOfSpeech:
        type: "string|null"

      translationZhTw:
        type: "string"
        required: true

      definitionEn:
        type: "string|null"

      keyDifference:
        type: "string"
        required: true

      usageContext:
        type: "string"
        required: true

      formality:
        type: "string|null"
        enum:
          - "formal"
          - "neutral"
          - "informal"
          - null

      commonCollocations:
        type: "array<Collocation>"
        maximum: 3

      example:
        type: "DictionaryExample"

      interchangeabilityNote:
        type: "string|null"

      isPrimaryWord:
        type: "boolean"

  dictionary_example:
    fields:
      english:
        type: "string"
      traditionalChinese:
        type: "string"

  collocation:
    fields:
      phrase:
        type: "string"
      translationZhTw:
        type: "string|null"

llm_design:
  strategy:
    recommended: "查詢時一次回傳主要單字、相似字與比較資料"

    reason:
      - "使用者點比較按鈕時不需要再次等待"
      - "避免第二次 API 呼叫"
      - "降低 LLM 成本"
      - "主要結果與比較結果保持一致"

    alternative:
      mode: "Lazy loading"
      description: >
        第一次查詢只產生主要單字和相似字；
        使用者按比較按鈕後才呼叫 LLM 產生完整比較。
      advantages:
        - "一般查字輸出 Token 較少"
      disadvantages:
        - "開啟比較畫面時需要等待"
        - "會增加第二次 API 呼叫"
        - "可能產生前後不一致的結果"

    mvp_recommendation: "第一次查詢直接回傳完整比較資料"

  maximum_similar_words: 4

  system_prompt_addition: |
    In addition to the primary dictionary result, identify up to four
    English words that are semantically similar to the primary word but
    differ meaningfully in usage, context, collocation, formality, or nuance.

    Only include words that are genuinely useful to compare.
    Do not return obscure words merely to fill the list.

    For each comparison word, provide:
    - word
    - normalizedWord
    - IPA pronunciation when reasonably confident
    - part of speech
    - concise Traditional Chinese meaning
    - English definition
    - the key difference from the primary word
    - typical usage context
    - formality level
    - up to three common collocations
    - one natural English example
    - Traditional Chinese translation of the example
    - whether and when it can replace the primary word

    Return valid JSON only and follow the supplied schema exactly.

  expected_response_example:
    query: "完成一個困難任務"

    primaryWord:
      word: "accomplish"
      normalizedWord: "accomplish"
      phonetic: "/əˈkʌmplɪʃ/"
      partOfSpeech: "verb"
      translationZhTw: "完成、達成"
      definitionEn: "To succeed in completing something difficult."
      examples:
        - english: "We accomplished the project on time."
          traditionalChinese: "我們準時完成了這個專案。"
      collocations:
        - phrase: "accomplish a task"
          translationZhTw: "完成任務"

    similarWords:
      - word: "achieve"
        normalizedWord: "achieve"
        phonetic: "/əˈtʃiːv/"
        partOfSpeech: "verb"
        shortTranslationZhTw: "達成目標"
        keyDifference: "強調取得成果或達到目標"
        relationshipType: "near_synonym"

      - word: "complete"
        normalizedWord: "complete"
        phonetic: "/kəmˈpliːt/"
        partOfSpeech: "verb"
        shortTranslationZhTw: "完整做完"
        keyDifference: "強調所有部分都已完成"
        relationshipType: "near_synonym"

      - word: "fulfill"
        normalizedWord: "fulfill"
        phonetic: "/fʊlˈfɪl/"
        partOfSpeech: "verb"
        shortTranslationZhTw: "履行、實現"
        keyDifference: "常用於履行承諾、責任或滿足需求"
        relationshipType: "contextual_synonym"

    comparison:
      title: "accomplish、achieve、complete 與 fulfill"

      quickSummary: >
        accomplish 強調完成具體且可能需要努力的任務；
        achieve 強調達成目標或獲得成果；
        complete 強調將所有部分完整做完；
        fulfill 常用於履行責任、承諾或實現期待。

      interchangeabilitySummary: >
        這些單字在部分語境中可以互換，但常見搭配和語意重點不同。

      words:
        - word: "accomplish"
          normalizedWord: "accomplish"
          phonetic: "/əˈkʌmplɪʃ/"
          partOfSpeech: "verb"
          translationZhTw: "完成、達成"
          definitionEn: "To succeed in completing something difficult."
          keyDifference: "強調完成一項具體且需要努力的任務"
          usageContext: "任務、工作、使命或困難事項"
          formality: "neutral"
          commonCollocations:
            - phrase: "accomplish a task"
              translationZhTw: "完成任務"
            - phrase: "accomplish a mission"
              translationZhTw: "完成使命"
          example:
            english: "The team accomplished its mission."
            traditionalChinese: "團隊完成了任務。"
          interchangeabilityNote: "有時可和 achieve 互換，但更偏向完成具體工作。"
          isPrimaryWord: true

        - word: "achieve"
          normalizedWord: "achieve"
          phonetic: "/əˈtʃiːv/"
          partOfSpeech: "verb"
          translationZhTw: "達成、取得"
          definitionEn: "To successfully reach a goal or desired result."
          keyDifference: "強調達成目標或取得成果"
          usageContext: "目標、成功、成果或高度成就"
          formality: "neutral"
          commonCollocations:
            - phrase: "achieve a goal"
              translationZhTw: "達成目標"
            - phrase: "achieve success"
              translationZhTw: "取得成功"
          example:
            english: "She achieved her lifelong goal."
            traditionalChinese: "她達成了畢生的目標。"
          interchangeabilityNote: "適合強調成果，不一定表示完成一項具體任務。"
          isPrimaryWord: false

favorite_design:
  storage:
    repository: "FavoritesRepository"
    file: "favorites.json"
    duplicate_key: "normalizedWord"

  behavior:
    add_from_comparison:
      steps:
        - "使用者點擊 ComparisonWordCard 的空心星星或加入按鈕"
        - "UI 立即切換成已收藏狀態"
        - "將該 ComparisonWord 轉換為 FavoriteWord"
        - "檢查 normalizedWord 是否已存在"
        - "不存在時寫入 favorites.json"
        - "成功後顯示 Snackbar"
        - "寫入失敗則還原 UI 狀態"

    remove_from_comparison:
      steps:
        - "使用者點擊實心星星或已加入按鈕"
        - "UI 立即切換成未收藏狀態"
        - "從 favorites.json 移除 normalizedWord"
        - "成功後顯示 Snackbar"
        - "移除失敗則還原 UI 狀態"

  favorite_word_mapping:
    id: "generateUUID"
    word: "comparisonWord.word"
    normalizedWord: "comparisonWord.normalizedWord"
    query: "originalDictionaryQuery"
    phonetic: "comparisonWord.phonetic"
    primaryPartOfSpeech: "comparisonWord.partOfSpeech"
    primaryTranslationZhTw: "comparisonWord.translationZhTw"
    source: "word_comparison"
    savedAt: "currentISODateTime"
    savedEntry:
      word: "comparisonWord.word"
      normalizedWord: "comparisonWord.normalizedWord"
      phonetic: "comparisonWord.phonetic"
      partOfSpeech: "comparisonWord.partOfSpeech"
      translationZhTw: "comparisonWord.translationZhTw"
      definitionEn: "comparisonWord.definitionEn"
      collocations: "comparisonWord.commonCollocations"
      examples:
        - "comparisonWord.example"

state_management:
  providers:
    dictionary_query_provider:
      responsibility:
        - "執行字典查詢"
        - "保存目前 DictionaryQueryResult"

    comparison_provider:
      responsibility:
        - "提供 WordComparison 資料"
        - "管理比較 UI 的 Loading、Success、Error"

    favorites_provider:
      responsibility:
        - "讀取我的單字"
        - "判斷每個 normalizedWord 是否已收藏"
        - "加入收藏"
        - "移除收藏"
        - "通知所有相關 UI 更新"

  favorite_state_rule: >
    DictionaryScreen、SimilarWordPreview 與 WordComparisonModal
    必須共用同一個 FavoritesProvider，不可以各自維護收藏狀態。

comparison_modal_states:
  loading:
    visible_when: "comparison 尚未產生"
    content:
      progress_indicator: true
      message: "正在比較這些單字..."

  success:
    visible_when: "comparison.words 長度至少為 2"
    content:
      - "快速理解"
      - "單字比較卡"
      - "收藏操作"

  error:
    content:
      message: "目前無法產生單字比較。"
      actions:
        - label: "重新嘗試"
          action: "reloadComparison"
        - label: "關閉"
          action: "closeModal"

  insufficient_words:
    condition: "相似字少於 1 個"
    behavior:
      - "停用比較按鈕"
      - "不開啟比較 UI"

validation_rules:
  - id: "VAL-001"
    rule: "主要單字不得出現在 similarWords 中。"

  - id: "VAL-002"
    rule: "similarWords 以 normalizedWord 去除重複。"

  - id: "VAL-003"
    rule: "相似字數量最多為 4，加上主要單字最多比較 5 個。"

  - id: "VAL-004"
    rule: "WordComparison.words 必須包含主要單字。"

  - id: "VAL-005"
    rule: "每個比較單字都必須有 keyDifference 與 usageContext。"

  - id: "VAL-006"
    rule: "不能只因為字義相關，就宣稱兩個字可以互換。"

  - id: "VAL-007"
    rule: "收藏狀態以 normalizedWord 判斷，不使用畫面索引。"

  - id: "VAL-008"
    rule: "收藏操作不得再次呼叫 LLM。"

error_handling:
  malformed_comparison_json:
    message: "AI 回傳的比較格式不正確。"
    action:
      - "執行一次格式修復"
      - "仍失敗則只顯示主要字典結果"
      - "隱藏比較按鈕"

  favorite_write_failed:
    message: "無法儲存我的單字，請重新嘗試。"
    action:
      - "還原收藏圖示"
      - "保留比較視窗"

  duplicate_favorite:
    behavior:
      - "不新增重複資料"
      - "直接顯示已收藏狀態"

  no_network:
    comparison_preloaded:
      behavior: "正常顯示已取得的比較資料"
    comparison_not_loaded:
      message: "目前無法連線，無法取得比較資料。"

testing:
  unit_tests:
    - "解析 similarWords JSON"
    - "解析 WordComparison JSON"
    - "主要單字不重複出現在相似字"
    - "相似字 normalizedWord 去重複"
    - "ComparisonWord 轉換成 FavoriteWord"
    - "重複收藏不新增第二筆"
    - "移除收藏"

  widget_tests:
    - "查詢成功後顯示相似單字區塊"
    - "無相似字時隱藏比較按鈕"
    - "點比較按鈕開啟比較 UI"
    - "比較 UI 顯示快速理解"
    - "每個單字顯示獨立收藏按鈕"
    - "收藏後空心星星變成實心"
    - "移除後實心星星變成空心"

  integration_tests:
    - "輸入中文並取得英文主要字與相似字"
    - "從主畫面進入單字比較"
    - "在比較 UI 收藏主要單字"
    - "在比較 UI 收藏相似單字"
    - "關閉比較 UI 後主畫面收藏狀態同步"
    - "重新啟動 App 後收藏仍存在"

acceptance_criteria:
  - "查詢成功後，主畫面最多顯示 4 個相似單字。"
  - "相似單字區塊包含明確的比較單字按鈕。"
  - "按下比較單字後，開啟可捲動的新 UI。"
  - "比較 UI 至少顯示核心差異、使用情境、搭配與例句。"
  - "每個單字都有獨立的加入我的單字按鈕。"
  - "已收藏單字顯示實心星星或已加入狀態。"
  - "相同單字不會重複寫入 favorites.json。"
  - "比較 UI 關閉後，收藏狀態仍與主畫面及我的單字同步。"

implementation_order:
  step_1:
    name: "擴充 LLM 回傳 Schema"
    tasks:
      - "加入 similarWords"
      - "加入 comparison"
      - "加入 JSON 驗證"

  step_2:
    name: "主畫面相似字"
    tasks:
      - "建立 SimilarWordsSection"
      - "建立 SimilarWordChip"
      - "建立比較單字按鈕"

  step_3:
    name: "比較 UI"
    tasks:
      - "建立 WordComparisonModal"
      - "建立 ComparisonWordCard"
      - "實作垂直捲動"
      - "顯示比較摘要與單字內容"

  step_4:
    name: "收藏整合"
    tasks:
      - "比較單字轉換為 FavoriteWord"
      - "整合 FavoritesProvider"
      - "實作加入與移除"
      - "同步不同畫面的收藏狀態"

  step_5:
    name: "測試"
    tasks:
      - "單元測試"
      - "Widget 測試"
      - "完整流程測試"