import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/historical_event.dart';

class EventsGallery extends StatefulWidget {
  final List<HistoricalEvent> events;
  final Function(DateTime) onEventSelected;
  final String? currentTimeKey;

  const EventsGallery({
    super.key,
    required this.events,
    required this.onEventSelected,
    this.currentTimeKey,
  });

  @override
  State<EventsGallery> createState() => _EventsGalleryState();
}

class _EventsGalleryState extends State<EventsGallery> {
  String _selectedCategory = 'all';
  
  final Map<String, String> _categories = {
    'all': 'Todos',
    'guerra': 'Guerra',
    'ciencia': 'Ciencia',
    'politico': 'Política',
    'desastre': 'Desastres',
    'historico': 'Histórico',
    'terrorismo': 'Terrorismo',
  };

  List<HistoricalEvent> get _filteredEvents {
    if (_selectedCategory == 'all') {
      return widget.events;
    }
    return widget.events
        .where((event) => event.category.toLowerCase() == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          _buildHeader(),
          _buildCategoryFilter(),
          Expanded(
            child: _buildEventsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.amber, size: 32),
          const SizedBox(width: 12),
          const Text(
            'Galería de Eventos Históricos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredEvents.length} eventos',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final categoryKey = _categories.keys.elementAt(index);
          final categoryName = _categories[categoryKey]!;
          final isSelected = _selectedCategory == categoryKey;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(categoryName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = categoryKey;
                });
              },
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedColor: Colors.amber.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.amber,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsGrid() {
    if (_filteredEvents.isEmpty) {
      return const Center(
        child: Text(
          'No hay eventos en esta categoría',
          style: TextStyle(color: Colors.white54, fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        final isCurrentEvent = event.time == widget.currentTimeKey;
        return _buildEventCard(event, isCurrentEvent);
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  Widget _buildEventCard(HistoricalEvent event, bool isCurrentEvent) {
    return GestureDetector(
      onTap: () {
        // Convertir hora HH:MM a DateTime
        final parts = event.time.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final now = DateTime.now();
        final eventTime = DateTime(now.year, now.month, now.day, hour, minute);
        
        widget.onEventSelected(eventTime);
        Navigator.pop(context); // Cerrar la galería
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isCurrentEvent
              ? Border.all(color: Colors.amber, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: isCurrentEvent
                  ? Colors.amber.withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen de fondo
              CachedNetworkImage(
                imageUrl: event.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.image_not_supported, color: Colors.white54, size: 48),
                ),
              ),
              
              // Gradiente overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              
              // Contenido
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de hora
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrentEvent ? Colors.amber : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: isCurrentEvent ? Colors.black : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            event.time,
                            style: TextStyle(
                              color: isCurrentEvent ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(event.category),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getCategoryEmoji(event.category) + ' ' + event.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Título
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Fecha
                    Text(
                      event.date,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Indicador de evento actual
              if (isCurrentEvent)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.black, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'guerra':
        return Colors.red.withOpacity(0.7);
      case 'ciencia':
        return Colors.blue.withOpacity(0.7);
      case 'politico':
      case 'política':
        return Colors.purple.withOpacity(0.7);
      case 'desastre':
        return Colors.orange.withOpacity(0.7);
      case 'terrorismo':
        return Colors.red[900]!.withOpacity(0.7);
      default:
        return Colors.grey.withOpacity(0.7);
    }
  }

  String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'guerra':
        return '⚔️';
      case 'ciencia':
        return '🔬';
      case 'politico':
      case 'política':
        return '🏛️';
      case 'desastre':
        return '🌋';
      case 'terrorismo':
        return '💣';
      default:
        return '📜';
    }
  }
}