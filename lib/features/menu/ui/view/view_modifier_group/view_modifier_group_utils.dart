String behaviorLabel(String behavior) {
  switch (behavior) {
    case 'fixed':
      return 'Fixed pricing';
    case 'none':
      return 'No price change';
    case 'addon':
    default:
      return 'Add-on pricing';
  }
}

