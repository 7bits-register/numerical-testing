properties([
    parameters([
        string(
            defaultValue: 'https://github.com/SeisSol/SeisSol.git', 
            description: 'seissol main repository', 
            name: 'SEISSOL_REPO',
            trim: true),
        string(
            defaultValue: 'ravil/gpu_plasticity', 
            description: 'branch to test', 
            name: 'SEISSOL_BRANCH',
            trim: true),
        string(
            defaultValue: '5e-6', 
            description: 'max abs difference', 
            name: 'EPS',
            trim: true),
        choice(
            choices: ['gpu-plasticity-elastic', 'convergence_elastic'], 
            description: 'scenario to test (see sub-folders)', 
            name: 'TEST_SCENARIO')
    ])
])

pipeline {
    agent {label 'master'}

    stages {
        stage('CleanWorkspace') {
            steps {
                deleteDir()
            }
        }
        stage('Clone') {
            environment {
                TRIMMED_BRANCH = sh(script:'echo ${GIT_BRANCH##origin/}', returnStdout: true).trim()
            }
            steps {
                git branch: "${env.TRIMMED_BRANCH}", url: "${GIT_URL}"
                script {
                    remoteCacheDir = "~/.seissol-aid"
                }
            }
        }

        stage('CloneSeisSol') {
            steps {
                script {
                    sh """
                    git clone --branch ${params.SEISSOL_BRANCH} --recurse-submodules ${params.SEISSOL_REPO} seissol
                    """
                }
            }
        }

        stage('ConvergenceTestGPU') {
            when {
                expression {
                    "${params.TEST_SCENARIO}" == 'convergence_elastic'
                }
            }
            steps {
                script {
                    dir('./seissol') {
                        sh """
                        for precision in double single; do
                            mkdir -p build_${precision} && cd build_${precision}
                            cp ../../convergence_elastic/* .
                            
                            cmake -DCMAKE_BUILD_TYPE=Release -DDEVICE_ARCH=${GPU_VENDOR} -DDEVICE_SUB_ARCH=${GPU_MODEL} \
                            -DHOST_ARCH=${RUNNER_HOST_ARCH} -DPRECISION=${precision} ..
                            
                            make -j4
                            mpirun -n 1 ./SeisSol_Release_?nvidia_?_elastic ./parameters.par
                            cd ..
                        done
                        """
                    }
                }
            }
        }


        stage('PlasticityElasticGPU') {
            when {
                expression {
                    "${params.TEST_SCENARIO}" == 'gpu-plasticity-elastic'
                }
            }
            steps {
                script {
                    sh """
                    mkdir -p  ./seissol/build
                    cp -r ./plasticity-elastic/* ./seissol/build
                    """
                    elasticDomainFile = "tpv13_cell.h5"
                    faultFile = "tpv13-fault_cell.h5"
                    dir('./seissol/build') {
                        sh """
                        cp ./config/* .
                        cmake .. -DCMAKE_BUILD_TYPE=Release -DPRECISION=double -DPLASTICITY=ON -DDEVICE_ARCH=${env.GPU_VENDOR} -DDEVICE_SUB_ARCH=${env.GPU_MODEL}
                        make -j5
                        pwd
                        mkdir ./output
                        mpirun -n 1 ./SeisSol_Release_* ./parameters.par
                        pwd
                        h5diff -v1 -d ${EPS} --exclude-path /mesh0/clustering ./output/${elasticDomainFile} ./output-double-reference/${elasticDomainFile}
                        h5diff -v1 -d ${EPS} ./output/${faultFile} ./output-double-reference/${faultFile}
                        pwd
                        """
                    }
                }
            }
        }
    }
}
