extension SizeLabelIntExt on int {
  String fileSizeLabel({int asFixed = 2}) {
    return toDouble().fileSizeLabel(asFixed: asFixed);
  }
}

extension SizeLabelDoubleExt on double {
  String fileSizeLabel({int asFixed = 2}) {
    String res = '';
    int pow = 1024;
    final labels = ['byte', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = this;
    while (size > pow) {
      size /= pow;
      i++;
    }

    res = '${size.toStringAsFixed(asFixed)} ${labels[i]}';

    return res;
  }
}
