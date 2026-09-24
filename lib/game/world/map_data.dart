import '../../models/location_dialogue.dart';

const double kWorldWidth = 3200;
const double kWorldHeight = 1800;

List<LocationModel> buildTownLocations() => [
  const LocationModel(
    id: 'school',
    name: 'School',
    x: 1400,
    y: 120,
    w: 400,
    h: 260,
    color: 0xFF6FA8DC,
  ),
  const LocationModel(
    id: 'church',
    name: 'Church',
    x: 120,
    y: 700,
    w: 340,
    h: 240,
    color: 0xFFD9D2E9,
  ),
  const LocationModel(
    id: 'plaza',
    name: 'Plaza',
    x: 1400,
    y: 700,
    w: 400,
    h: 300,
    color: 0xFF93C47D,
  ),
  const LocationModel(
    id: 'park',
    name: 'Park',
    x: 2280,
    y: 700,
    w: 340,
    h: 240,
    color: 0xFF6AA84F,
  ),
  const LocationModel(
    id: 'home',
    name: 'Home',
    x: 1400,
    y: 1180,
    w: 400,
    h: 260,
    color: 0xFFE6B8AF,
  ),
  const LocationModel(
    id: 'workplace',
    name: 'Café',
    x: 1400,
    y: 1560,
    w: 400,
    h: 200,
    color: 0xFFFFD966,
  ),
];
