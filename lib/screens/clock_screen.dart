import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/clock_provider.dart';
import '../providers/events_provider.dart';
import '../widgets/analog_clock.dart';
import '../widgets/digital_clock.dart';
import '../widgets/events_gallery.dart';

class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<ClockProvider, EventsProvider>(
        builder: (context, clockProvider, eventsProvider, child) {
          final currentEvent =
              eventsProvider.getEventByTime(clockProvider.getTimeKey());
          final backgroundImage = currentEvent?.imageUrl ??
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop&q=80';

          return Stack(
            children: [
              // Imagen de fondo
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: backgroundImage,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 500),
                  fadeOutDuration: const Duration(milliseconds: 300),
                  placeholder: (context, url) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.amber,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[900]!,
                          Colors.black,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported,
                              color: Colors.white54, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Imagen no disponible',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay oscuro
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.9),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Botones superiores
              Positioned(
                top: 40,
                left: 20,
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: clockProvider.toggleClockMode,
                      icon: Icon(clockProvider.isAnalogMode
                          ? Icons.access_time
                          : Icons.watch_later),
                      label: Text(
                          clockProvider.isAnalogMode ? 'Digital' : 'Análogo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.9,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            builder: (context, scrollController) =>
                                EventsGallery(
                              events: eventsProvider.getAllEvents(),
                              currentTimeKey: clockProvider.getTimeKey(),
                              onEventSelected: (DateTime selectedTime) {
                                clockProvider.setTime(selectedTime);
                              },
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.grid_view),
                      label: const Text('Galería'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.withOpacity(0.2),
                        foregroundColor: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),

              // Indicador de modo exploración
              if (clockProvider.isManualMode)
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🔍 Modo Exploración',
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              // Contenido central
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Reloj
                    clockProvider.isAnalogMode
                        ? AnalogClockWidget(
                            time: clockProvider.currentTime, size: 300)
                        : DigitalClockWidget(time: clockProvider.currentTime),
                    const SizedBox(height: 20),

                    // Fecha
                    Text(
                      DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es_ES')
                          .format(clockProvider.currentTime),
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              blurRadius: 8,
                              color: Colors.black,
                              offset: Offset(2, 2))
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Información del evento
                    if (currentEvent != null)
                      _buildEventInfo(context, currentEvent, eventsProvider)
                    else
                      _buildNoEventInfo(context),
                  ],
                ),
              ),

// Botones de control - RESPONSIVE MEJORADO
              Positioned(
                // Lógica adaptativa:
                // - Desktop/Tablet (>700px altura): botones ABAJO
                // - Móvil portrait (600-700px): botones a 70% altura (debajo del evento)
                // - Móvil landscape (<600px): botones ARRIBA
                bottom: MediaQuery.of(context).size.height > 700 ? 30 : null,
                top: MediaQuery.of(context).size.height > 700
                    ? null
                    : MediaQuery.of(context).size.height > 600
                        ? MediaQuery.of(context).size.height *
                            0.70 // Móvil portrait: 70% altura
                        : 100, // Móvil landscape: arriba a 100px
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: _buildControlButton(
                          icon: Icons.skip_previous,
                          label: 'Anterior',
                          onPressed: () => clockProvider.navigateTime(-1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildControlButton(
                          icon: clockProvider.isManualMode
                              ? Icons.play_arrow
                              : Icons.pause,
                          label: clockProvider.isManualMode
                              ? 'Tiempo Real'
                              : 'Explorar',
                          onPressed: clockProvider.toggleManualMode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildControlButton(
                          icon: Icons.skip_next,
                          label: 'Siguiente',
                          onPressed: () => clockProvider.navigateTime(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventInfo(
      BuildContext context, dynamic event, EventsProvider eventsProvider) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🕐 ${event.time} - ${event.date}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.amber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  eventsProvider.isFavorite(event.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.amber,
                ),
                onPressed: () => eventsProvider.toggleFavorite(event),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.title,
            style: TextStyle(
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: isMobile ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            event.description,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.white70,
              height: 1.5,
            ),
            maxLines: isMobile ? 3 : 5,
            overflow: TextOverflow.ellipsis,
          ),
          if (event.source.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Fuente: ${event.source}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoEventInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Column(
        children: [
          Text(
            'No hay eventos históricos registrados para este minuto',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Navega por el tiempo para descubrir momentos que cambiaron la historia',
            style: TextStyle(fontSize: 14, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.85),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 0,
        ),
      ),
    );
  }
}
