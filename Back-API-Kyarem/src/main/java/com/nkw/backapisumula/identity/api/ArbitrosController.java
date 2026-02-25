package com.nkw.backapisumula.identity.api;

import com.nkw.backapisumula.identity.Profile;
import com.nkw.backapisumula.identity.service.ProfileService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Lista árbitros cadastrados (profiles.role = 'arbitro').
 *
 * Útil para telas administrativas (atribuição de arbitragem, filtros, etc.).
 */
@RestController
@RequestMapping("/api/v1/arbitros")
public class ArbitrosController {

    private final ProfileService profileService;

    public ArbitrosController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('admin','delegado')")
    public List<ArbitroResponse> list() {
        return profileService.listArbitros().stream().map(ArbitroResponse::from).toList();
    }

    public record ArbitroResponse(
            UUID id,
            String nomeExibicao,
            String fotoUrl,
            String telefone,
            String role,
            OffsetDateTime criadoEm,
            OffsetDateTime atualizadoEm
    ) {
        public static ArbitroResponse from(Profile p) {
            return new ArbitroResponse(
                    p.getId(),
                    p.getNomeExibicao(),
                    p.getFotoUrl(),
                    p.getTelefone(),
                    p.getRole(),
                    p.getCriadoEm(),
                    p.getAtualizadoEm()
            );
        }
    }
}
