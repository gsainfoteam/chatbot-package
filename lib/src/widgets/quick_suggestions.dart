import 'package:flutter/material.dart';

class QuickSuggestion {
  const QuickSuggestion({required this.icon, required this.label});

  final String icon;
  final String label;
}

const List<QuickSuggestion> kQuickSuggestions = [
  QuickSuggestion(icon: '📅', label: '학사 일정'),
  QuickSuggestion(icon: '✏️', label: '수강신청 방법'),
  QuickSuggestion(icon: '💰', label: '장학금 안내'),
  QuickSuggestion(icon: '🪪', label: '학생증 발급'),
  QuickSuggestion(icon: '📶', label: 'Wi-Fi 연결'),
  QuickSuggestion(icon: '🗺️', label: '캠퍼스 맵'),
  QuickSuggestion(icon: '🎓', label: '졸업 요건 확인'),
  QuickSuggestion(icon: '📖', label: '전공 선언 방법'),
  QuickSuggestion(icon: '📞', label: '주요 부서 연락처'),
  QuickSuggestion(icon: '🏫', label: '휴학/복학 절차'),
];

class QuickSuggestionsSection extends StatelessWidget {
  const QuickSuggestionsSection({
    super.key,
    required this.onSelect,
  });

  final void Function(String text) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text(
              '무엇을 도와드릴까요?',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '이런 것들을 물어보세요',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 340 ? 1 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: crossAxisCount == 1 ? 5.5 : 3.2,
                ),
                itemCount: kQuickSuggestions.length,
                itemBuilder: (context, index) {
                  final item = kQuickSuggestions[index];
                  return _SuggestionButton(
                    suggestion: item,
                    onTap: () => onSelect(item.label),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestionButton extends StatelessWidget {
  const _SuggestionButton({
    required this.suggestion,
    required this.onTap,
  });

  final QuickSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Text(suggestion.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  suggestion.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
