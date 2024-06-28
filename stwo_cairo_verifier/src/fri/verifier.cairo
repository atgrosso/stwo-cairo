use core::result::ResultTrait;
use core::array::ArrayTrait;
use stwo_cairo_verifier::channel::ChannelTrait;
use stwo_cairo_verifier::fields::qm31::{QM31, qm31};
use stwo_cairo_verifier::fields::m31::{m31};
use stwo_cairo_verifier::vcs::verifier::MerkleDecommitment;
use stwo_cairo_verifier::channel::Channel;

const CIRCLE_TO_LINE_FOLD_STEP: u32 = 1;
const FOLD_STEP: u32 = 1;

pub fn pow(base: u32, exponent: u32) -> u32 {
    // TODO: implement or include from alexandria
    1
}

#[derive(Drop)]
pub enum FriVerificationError {
    InvalidNumFriLayers,
    LastLayerDegreeInvalid,
}

#[derive(Copy, Drop)]
pub struct LineDomain {
}

#[generate_trait]
impl LineDomainImpl of LineDomainTrait {
    fn double(self: LineDomain) -> LineDomain {
        // TODO: implement
        self
    }
}

#[derive(Drop)]
pub struct LinePoly {
    coeffs: Array<QM31>,
    log_size: u32,
}

#[generate_trait]
impl LinePolyImpl of LinePolyTrait {
    fn len(self: @LinePoly) -> usize {
        // TODO: implement
        1
    }
}


#[derive(Drop)]
pub struct Queries {
    pub positions: Array<usize>,
    pub log_domain_size: u32,
}

#[derive(Drop)]
struct FriLayerVerifier {
    degree_bound: u32,
    domain: LineDomain,
    folding_alpha: QM31,
    layer_index: usize,
    proof: @FriLayerProof,
}


#[derive(Clone, Copy, Drop)]
pub struct FriConfig {
    log_blowup_factor: u32,
    log_last_layer_degree_bound: usize,
    n_queries: usize,
}

#[derive(Drop)]
pub struct FriLayerProof {
    pub evals_subset: Array<QM31>,
    pub decommitment: MerkleDecommitment,
    pub decomposition_coeff: QM31,
    pub commitment: felt252,
}

#[derive(Drop)]
pub struct FriProof {
    pub inner_layers: Array<FriLayerProof>,
    pub last_layer_poly: LinePoly,
}

#[derive(Drop)]
pub struct FriVerifier {
    config: FriConfig,
    circle_poly_alpha: QM31,
    expected_query_log_domain_size: u32,
    column_bounds: Array<u32>,
    inner_layers: Array<FriLayerVerifier>,
    last_layer_domain: LineDomain,
    last_layer_poly: LinePoly,
    queries: Option<Queries>,
}

#[generate_trait]
impl FriVerifierImpl of FriVerifierTrait {
    fn commit(mut channel: Channel, config: FriConfig, proof: FriProof, column_bounds: Array<u32>) -> Result<FriVerifier, FriVerificationError> {
        let max_column_bound = column_bounds[0];
        let expected_query_log_domain_size = *max_column_bound + config.log_blowup_factor;
        let circle_poly_alpha = channel.draw_felt();

        let mut inner_layers = array![];
        let mut layer_bound = *max_column_bound - CIRCLE_TO_LINE_FOLD_STEP;
        let mut layer_domain = LineDomain{};

        let layer_index = 0;
        let mut invalid_fri_layers_number = false;
        while layer_index < proof.inner_layers.len() {
            let proof = proof.inner_layers[layer_index];
            channel.mix_digest(*proof.commitment);
            channel.mix_felts(array![*proof.decomposition_coeff].span());
            let folding_alpha = channel.draw_felt();
            inner_layers.append(FriLayerVerifier {
                degree_bound: layer_bound,
                domain: layer_domain,
                folding_alpha,
                layer_index,
                proof,
            });

            if layer_bound >= FOLD_STEP {
                layer_bound = layer_bound - FOLD_STEP;
            } else {
                invalid_fri_layers_number = true;
                break;
            }
            layer_domain = layer_domain.double();
        };

        if invalid_fri_layers_number {
            return Result::Err(FriVerificationError::InvalidNumFriLayers);
        }

        if layer_bound != config.log_last_layer_degree_bound {
            return Result::Err(FriVerificationError::InvalidNumFriLayers);
        }

        let last_layer_domain = LineDomain{};
    
        if proof.last_layer_poly.len() > pow(2, config.log_last_layer_degree_bound) {
            return Result::Err(FriVerificationError::LastLayerDegreeInvalid);
        }

        channel.mix_felts(proof.last_layer_poly.coeffs.span());

        Result::Ok(FriVerifier {
            config,
            circle_poly_alpha,
            column_bounds,
            expected_query_log_domain_size,
            inner_layers,
            last_layer_domain,
            last_layer_poly: proof.last_layer_poly,
            queries: Option::None
        })
    }

    // fn decommit_on_queries(
    //     self: FriVerifier,
    //     queries: @Queries,
    //     decommitted_values: Array<SparseCircleEvaluation>
    // ) {

    // }
}


use core::poseidon::poseidon_hash_span;
#[test]
fn test_fri_verifier() {
    let log_degree = 3;
    let proof = FriProof {
        inner_layers: array![FriLayerProof {
            evals_subset: array![qm31(1654551922, 1975507039, 724492960, 302041406)],
            decommitment: MerkleDecommitment {
                hash_witness: array![
                    0x02894fb64f5b5ad74ad6868ded445416d52840c2c4a36499f0eb37a03841bfc8,
                    0x05d3f79e2cfd15b605e1e8eb759aa79e775e89df7c4ae5966efe3b96d3554003
                ],
                column_witness: array![]
            },
            decomposition_coeff: qm31(0, 0, 0, 0),
            commitment: 0x03e5bad5822d062c05ff947d282dc2d56a6a420d14f2f74972bb5b01287731a7
        }],
        last_layer_poly: LinePoly{
            coeffs: array![
                qm31(1700411592, 1718151617, 1386964511, 2008082344), 
                qm31(1700411592, 1718151617, 1386964511, 2008082344)
            ],
            log_size: 1
        }
    };

    let log_domain_size = 4;
    let queries = Queries {positions: array![5], log_domain_size};
    let channel = ChannelTrait::new(0x00);
    let config = FriConfig { log_blowup_factor: 1, log_last_layer_degree_bound: 1, n_queries: 1 };
    let bound = array![log_degree];
    // let verifier = FriVerifierImpl::commit(channel, config, proof, bound).unwrap();
    // let decommitment_value = array![qm31(1990458477, 0, 0, 0), qm31(1966717173, 0, 0, 0), ];
    // verifier.decommit_on_queries(@queries, array![decommitment_value])

    // assert!(verifier.verify(channel, proof));
}
