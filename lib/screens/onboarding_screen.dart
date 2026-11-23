import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  bool _saving = false;

  static const _slides = [
    _Slide(
      title: 'Know where your money goes',
      description: 'Track income and expenses, and see your cash flow at a glance.',
    ),
    _Slide(
      title: 'Make a plan that feels right',
      description: 'Set monthly budgets, manage accounts and savings goals in one place.',
    ),
    _Slide(
      title: 'Your money stays private',
      description: 'Your records stay on this device. No account or internet connection needed.',
    ),
  ];

  Future<void> _advance() async {
    if (_page < _slides.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeInOutCubic,
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onComplete();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final lastPage = _page == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.softGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.brand, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text('Pennywise', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.brandDark)),
                  const Spacer(),
                  Text(
                    '${(_page + 1).toString().padLeft(2, '0')} / 03',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320, maxHeight: 270),
                            child: AspectRatio(
                              aspectRatio: 1.12,
                              child: _Artwork(index: index),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                t(_slides[index].title),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 27, height: 1.16),
                              ),
                              const SizedBox(height: 13),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 315),
                                child: Text(
                                  t(_slides[index].description),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.muted, height: 1.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final active = index == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 25 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.brand : AppTheme.brand.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _advance,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(t(lastPage ? 'Continue' : 'Next')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({required this.title, required this.description});
  final String title;
  final String description;
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: AppTheme.brand.withValues(alpha: .07), blurRadius: 32, offset: const Offset(0, 14)),
        ],
      ),
      child: switch (index) {
        0 => _moneyArtwork(),
        1 => _budgetArtwork(),
        _ => _privacyArtwork(),
      },
    );
  }

  Widget _moneyArtwork() {
    return Column(
      children: [
        Row(children: [
          _iconTile(Icons.account_balance_wallet_rounded, AppTheme.softGreen, AppTheme.brand),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 95, height: 8, decoration: _bar(AppTheme.ink.withValues(alpha: .75))),
            const SizedBox(height: 7),
            Container(width: 65, height: 6, decoration: _bar(AppTheme.border)),
          ])),
          const Icon(Icons.more_horiz_rounded, color: AppTheme.muted),
        ]),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.softGreen, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 82, height: 6, decoration: _bar(AppTheme.brand.withValues(alpha: .35))),
            const SizedBox(height: 9),
            const Text('$4,850.00', style: TextStyle(color: AppTheme.brandDark, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8)),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: List.generate(12, (i) {
              final heights = [18.0, 25.0, 21.0, 35.0, 29.0, 43.0, 31.0, 48.0, 39.0, 54.0, 44.0, 62.0];
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(height: heights[i], decoration: BoxDecoration(color: AppTheme.brand.withValues(alpha: i == 11 ? 1 : .25), borderRadius: BorderRadius.circular(4))),
              ));
            })),
          ]),
        ),
        const Spacer(),
        Row(children: [
          Expanded(child: _amountCard(Icons.south_west_rounded, '$5,200', AppTheme.income)),
          const SizedBox(width: 10),
          Expanded(child: _amountCard(Icons.north_east_rounded, '$350', AppTheme.expense)),
        ]),
      ],
    );
  }

  Widget _budgetArtwork() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _iconTile(Icons.savings_rounded, const Color(0xFFE8F4EC), AppTheme.income),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 105, height: 8, decoration: _bar(AppTheme.ink.withValues(alpha: .75))),
          const SizedBox(height: 7),
          Container(width: 70, height: 6, decoration: _bar(AppTheme.border)),
        ])),
        const Icon(Icons.more_horiz_rounded, color: AppTheme.muted),
      ]),
      const SizedBox(height: 24),
      Container(width: 110, height: 6, decoration: _bar(AppTheme.border)),
      const SizedBox(height: 9),
      const Text('$1,200.00', style: TextStyle(color: AppTheme.ink, fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -.8)),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: const LinearProgressIndicator(value: .68, minHeight: 10, backgroundColor: AppTheme.border, color: AppTheme.income),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Container(width: 38, height: 6, decoration: _bar(AppTheme.income)),
        const Spacer(),
        Container(width: 54, height: 6, decoration: _bar(AppTheme.border)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: AppTheme.canvas, borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          _iconTile(Icons.flag_rounded, AppTheme.softGreen, AppTheme.brand, size: 34),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 85, height: 7, decoration: _bar(AppTheme.ink.withValues(alpha: .65))),
            const SizedBox(height: 7),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: .72, minHeight: 5, backgroundColor: AppTheme.border, color: AppTheme.brand)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded, color: AppTheme.income, size: 19),
        ]),
      ),
    ]);
  }

  Widget _privacyArtwork() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 145,
        height: 145,
        decoration: BoxDecoration(
          color: AppTheme.softGreen,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.brand.withValues(alpha: .12), width: 1.5),
        ),
        child: const Icon(Icons.shield_lock_rounded, color: AppTheme.brand, size: 78),
      ),
      const SizedBox(height: 22),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _privacyChip(Icons.phone_android_rounded),
        const SizedBox(width: 10),
        _privacyChip(Icons.wifi_off_rounded),
        const SizedBox(width: 10),
        _privacyChip(Icons.lock_rounded),
      ]),
      const SizedBox(height: 18),
      Container(width: 145, height: 7, decoration: _bar(AppTheme.border)),
      const SizedBox(height: 8),
      Container(width: 95, height: 7, decoration: _bar(AppTheme.softGreen)),
    ]);
  }

  Widget _iconTile(IconData icon, Color background, Color foreground, {double size = 38}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: foreground, size: size * .52),
    );
  }

  Widget _amountCard(IconData icon, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.canvas, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Flexible(child: Text(amount, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800))),
      ]),
    );
  }

  Widget _privacyChip(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(color: AppTheme.canvas, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppTheme.border)),
      child: Icon(icon, color: AppTheme.brand, size: 19),
    );
  }

  BoxDecoration _bar(Color color) => BoxDecoration(color: color, borderRadius: BorderRadius.circular(8));
}
