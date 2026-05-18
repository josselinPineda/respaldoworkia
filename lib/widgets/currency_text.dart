import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workia/presentation/viewmodels/empresa_viewmodel.dart';
import 'package:intl/intl.dart';

class CurrencyText extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign? textAlign;

  const CurrencyText(
    this.value, {
    super.key,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EmpresaViewModel>(
      builder: (context, empresaVM, child) {
        final tasa = empresaVM.empresa?.tasaCambio;
        final locale = Localizations.localeOf(context);
        final isSpanish = locale.languageCode == 'es';
        final hasExchange = isSpanish && tasa != null && tasa > 0;

        double displayAmount = value;
        // Si no hay tasa de cambio configurada, mostrar en USD (también en español).
        String symbol = hasExchange ? 'L' : '\$';

        // Formateador base
        final formatter = NumberFormat.currency(
          symbol: '', // Manual symbol handling
          decimalDigits: 2,
          locale: 'en_US', // Keep logic simple: 1,234.56 format
        );

        // En español mostramos siempre Lempiras. Si hay tasa de cambio, convertimos;
        // si no, mostramos el valor tal cual, pero con símbolo L.
        if (hasExchange) {
          displayAmount = value * tasa;
        }

        final formattedValue = formatter.format(displayAmount).trim();

        return Text(
          '$prefix$symbol$formattedValue$suffix',
          style: style,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
        );
      },
    );
  }
}
