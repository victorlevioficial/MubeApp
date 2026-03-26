class VenueOption {
  final String id;
  final String label;

  const VenueOption({required this.id, required this.label});
}

const List<VenueOption> venueTypeOptions = [
  VenueOption(id: 'bar', label: 'Bar'),
  VenueOption(id: 'pub', label: 'Pub'),
  VenueOption(id: 'restaurant', label: 'Restaurante'),
  VenueOption(id: 'cafe', label: 'Cafe'),
  VenueOption(id: 'concert_hall', label: 'Casa de Show'),
  VenueOption(id: 'events_space', label: 'Espaco de Eventos'),
  VenueOption(id: 'nightclub', label: 'Balada'),
  VenueOption(id: 'cultural_center', label: 'Centro Cultural'),
  VenueOption(id: 'hotel', label: 'Hotel'),
  VenueOption(id: 'other', label: 'Outro'),
];

const List<VenueOption> venueAmenityOptions = [
  VenueOption(id: 'stage', label: 'Palco'),
  VenueOption(id: 'sound_system', label: 'Sistema de Som'),
  VenueOption(id: 'lighting', label: 'Iluminacao'),
  VenueOption(id: 'dressing_room', label: 'Camarim'),
  VenueOption(id: 'backstage', label: 'Backstage'),
  VenueOption(id: 'parking', label: 'Estacionamento'),
  VenueOption(id: 'accessibility', label: 'Acessibilidade'),
  VenueOption(id: 'air_conditioning', label: 'Ar-condicionado'),
  VenueOption(id: 'security', label: 'Seguranca'),
  VenueOption(id: 'open_air', label: 'Area Aberta'),
];

String? venueTypeLabel(String? venueTypeId) {
  if (venueTypeId == null || venueTypeId.trim().isEmpty) {
    return null;
  }

  for (final option in venueTypeOptions) {
    if (option.id == venueTypeId) {
      return option.label;
    }
  }
  return venueTypeId;
}

String venueAmenityLabel(String amenityId) {
  for (final option in venueAmenityOptions) {
    if (option.id == amenityId) {
      return option.label;
    }
  }
  return amenityId;
}

List<String> venueAmenityLabels(Iterable<String> amenityIds) {
  return amenityIds.map(venueAmenityLabel).toList(growable: false);
}
