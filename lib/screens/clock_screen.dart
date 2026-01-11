import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/clock_provider.dart';
import '../providers/events_provider.dart';
import '../widgets/analog_clock.dart';
import '../widgets/digital_clock.dart';

class ClockScreen extends StatelessWidget {
  const ClockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<ClockProvider, EventsProvider>(
        builder: (context, clockProvider, eventsProvider, child) {
          final currentEvent = eventsProvider.getEventByTime(clockProvider.getTimeKey());
          final backgroundImage = currentEvent?.imageUrl ?? 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1600&h=900&fit=crop';

          return Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: backgroundImage,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.black),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black,
                    child: const Icon(Icons.error, color: Colors.white),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.6)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 20,
                child: ElevatedButton.icon(
                  onPressed: clockProvider.toggleClockMode,
                  icon: Icon(clockProvider.isAnalogMode ? Icons.access_time : Icons.watch_later),
                  label: Text(clockProvider.isAnalogMode ? 'Digital' : 'Análogo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (clockProvider.isManualMode)
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('🔍 Modo Exploración', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600)),
                  ),
                ),
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    clockProvider.isAnalogMode
                        ? AnalogClockWidget(time: clockProvider.currentTime, size: 300)
                        : DigitalClockWidget(time: clockProvider.currentTime),
                    const SizedBox(height: 20),
                    Text(
                      DateFormat('EEEE, d \'de\' MMMM \'de\' y', 'es_ES').format(clockProvider.currentTime),
                      style: const TextStyle(fontSize: 24, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black, offset: Offset(2, 2))]),
                    ),
                    const SizedBox(height: 40),
                    if (currentEvent != null) _buildEventInfo(context, currentEvent, eventsProvider) else _buildNoEventInfo(context),
                  ],
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(icon: Icons.skip_previous, label: 'Anterior', onPressed: () => clockProvider.navigateTime(-1)),
                    const SizedBox(width: 12),
                    _buildControlButton(
                      icon: clockProvider.isManualMode ? Icons.play_arrow : Icons.pause,
                      label: clockProvider.isManualMode ? 'Tiempo Real' : 'Explorar',
                      onPressed: clockProvider.toggleManualMode,
                    ),
                    const SizedBox(width: 12),
                    _buildControlButton(icon: Icons.skip_next, label: 'Siguiente', onPressed: () => clockProvider.navigateTime(1)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventInfo(BuildContext context, dynamic event, EventsProvider eventsProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('🕐 ${event.time} - ${event.date}', style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(eventsProvider.isFavorite(event.id) ? Icons.favorite : Icons.favorite_border, color: Colors.amber),
                onPressed: () => eventsProvider.toggleFavorite(event),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Text(event.description, style: const TextStyle(fontSize: 16, color: Colors.white70, height: 1.5)),
          if (event.source.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Fuente: ${event.source}', style: const TextStyle(fontSize: 12, color: Colors.white38, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildNoEventInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(15)),
      child: const Column(
        children: [
          Text('No hay eventos históricos registrados para este minuto', style: TextStyle(fontSize: 16, color: Colors.white54, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text('Navega por el tiempo para descubrir momentos que cambiaron la historia', style: TextStyle(fontSize: 14, color: Colors.white38), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}