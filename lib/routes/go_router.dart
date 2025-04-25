import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:volleyball_tournament_app/controller/data_controller.dart';
import 'package:volleyball_tournament_app/pages/home_page.dart';
import 'package:volleyball_tournament_app/pages/init_tournament/init_tournament_page.dart';
import 'package:volleyball_tournament_app/pages/players/players_page_mobile.dart';
import 'package:volleyball_tournament_app/pages/tournament/knockout_stage/knockout_match_mobile_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/knockout_stage/knockout_stage_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/knockout_stage_keys/knockout_stage_keys_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/matches_chaves/matches_chaves_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/podium/podium_page.dart';
import 'package:volleyball_tournament_app/pages/tournament/settings/settings_page.dart';

import '../pages/history/history_page.dart';
import '../pages/players/players_page.dart';
import '../pages/responsive/responsive_layout.dart';
import '../pages/tournament/matches_categoria/matches_mobile_page.dart';
import '../pages/tournament/matches_categoria/matches_page.dart';
import '../pages/tournament/tournament_mobile_page.dart';
import '../pages/tournament/tournament_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/players',
        builder: (context, state) => const ResponsiveLayout(mobileScreen: PlayersPageMobile(), desktopScreen: PlayersPage()),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryPage(),
      ),
      GoRoute(
        path: '/init_tournament',
        redirect: (context, state) {
          final dataController = Provider.of<DataController>(context, listen: false);
          if(dataController.tournament?.nomeTorneio?.isEmpty ?? true) {
            return '/init_tournament';
          }

          return null;
        },
        builder: (context, state) => const ResponsiveLayout(
          mobileScreen: InitTournamentPage(),
          desktopScreen: InitTournamentPage(),
        ),
        routes: [
          GoRoute(
            name: 'choose-players',
            path: 'choose-players',
            builder: (context, state) => const ResponsiveLayout(
              mobileScreen: TournamentMobilePage(),
              desktopScreen: TournamentPage(),
            ),
          ),
        ]
      ),
      GoRoute(
        name: 'matches',
        path: '/tournament/:nomeDoTorneio/match',
        redirect: (context, state) async {
          final dataController = Provider.of<DataController>(context, listen: false);
          final tournamentName = state.pathParameters['nomeDoTorneio'] ?? '';
          final isActive = await dataController.checkIfIsActive(nomeDoTorneio: tournamentName);
          if(!isActive) {
            return '/';
          }

          return null;
        },
        builder: (context, state) {
          final tournamentName = state.pathParameters['nomeDoTorneio'] ?? '';
          final matchType = state.uri.queryParameters;
          if(matchType.containsValue('keys')) {
            return ResponsiveLayout(
              mobileScreen: MatchesChavesPage(tournamentName: tournamentName),
              desktopScreen: MatchesChavesPage(tournamentName: tournamentName),
            );
          }
          return ResponsiveLayout(
            mobileScreen: MatchesMobilePage(tournamentName: tournamentName),
            desktopScreen: MatchesPage(tournamentName: tournamentName),
          );
        },
        routes: [
          GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) {
                return const SettingsPage();
              }
          ),
          GoRoute(
              path: '/knockout-stage',
              name: 'fase2',
              builder: (context, state) {
                final tournamentName = state.pathParameters['nomeDoTorneio'] ?? '';
                final matchType = state.uri.queryParameters;
                if(matchType.containsValue('keys')) {
                  return const KnockoutStageKeysPage();
                }
                return ResponsiveLayout(
                    mobileScreen: const KnockoutMatchMobilePage(),
                    desktopScreen: KnockoutStagePage(nomeTorneio: tournamentName)
                );
              }
          ),
        ]
      ),
      GoRoute(
          name: 'podium',
          path: '/tournament/:nomeDoTorneio/podium',
          builder: (context, state) {
            final tournamentName = state.pathParameters['nomeDoTorneio'] ?? '';
            return PodiumPage(tournamentName: tournamentName);
          }
      )
    ],
  );
}